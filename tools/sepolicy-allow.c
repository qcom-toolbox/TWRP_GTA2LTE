/*
 * sepolicy-allow: give SELinux domains unrestricted access in a binary
 * (kernel) policy, both as source and as target of every rule.
 *
 *   sepolicy-allow <in> <out> <domain>...
 *
 * For each domain D this is the same as magiskpolicy's
 *   "allow D * * *" "allow * D * *" "permissive D"
 *
 * Needed because this device's Samsung kernel is built with
 * config_always_enforce: setenforce 0 fails and permissive domains are
 * still enforced, so TWRP's "permissive recovery;" does nothing and TWRP
 * dies on the first denial (execmem, among others).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sepol/policydb/avtab.h>
#include <sepol/policydb/policydb.h>
#include <sepol/policydb/services.h>

static int allow(policydb_t *p, uint16_t src, uint16_t tgt, uint16_t cls)
{
	avtab_key_t key = {
		.source_type = src,
		.target_type = tgt,
		.target_class = cls,
		.specified = AVTAB_ALLOWED,
	};
	avtab_datum_t *d = avtab_search(&p->te_avtab, &key);
	if (d) {
		d->data = ~0U;
		return 0;
	}
	avtab_datum_t nd = { .data = ~0U };
	return avtab_insert(&p->te_avtab, &key, &nd);
}

int main(int argc, char **argv)
{
	policydb_t p;
	struct policy_file pf;
	FILE *f;
	int i;

	if (argc < 4) {
		fprintf(stderr, "usage: %s <in> <out> <domain>...\n", argv[0]);
		return 2;
	}

	f = fopen(argv[1], "rb");
	if (!f) {
		perror(argv[1]);
		return 1;
	}
	policy_file_init(&pf);
	pf.type = PF_USE_STDIO;
	pf.fp = f;
	if (policydb_init(&p) || policydb_read(&p, &pf, 0)) {
		fprintf(stderr, "%s: can't read policy\n", argv[1]);
		return 1;
	}
	fclose(f);

	for (i = 3; i < argc; i++) {
		type_datum_t *dom = hashtab_search(p.p_types.table, argv[i]);
		uint32_t t, c;

		if (!dom) {
			fprintf(stderr, "type %s not in policy\n", argv[i]);
			return 1;
		}
		/*
		 * Rules keyed on attributes cover every type that has the
		 * attribute, which keeps the policy small (the ramdisk size is
		 * limited by sboot). A type with no attribute at all - its
		 * type_attr_map holds only itself - gets its own rule.
		 */
		for (t = 1; t <= p.p_types.nprim; t++) {
			if (p.type_val_to_struct[t - 1]->flavor != TYPE_ATTRIB &&
			    ebitmap_cardinality(&p.type_attr_map[t - 1]) > 1)
				continue;
			for (c = 1; c <= p.p_classes.nprim; c++) {
				if (allow(&p, dom->s.value, t, c) ||
				    allow(&p, t, dom->s.value, c)) {
					fprintf(stderr, "out of memory\n");
					return 1;
				}
			}
		}
		if (ebitmap_set_bit(&p.permissive_map, dom->s.value, 1)) {
			fprintf(stderr, "out of memory\n");
			return 1;
		}
	}

	f = fopen(argv[2], "wb");
	if (!f) {
		perror(argv[2]);
		return 1;
	}
	policy_file_init(&pf);
	pf.type = PF_USE_STDIO;
	pf.fp = f;
	if (policydb_write(&p, &pf)) {
		fprintf(stderr, "%s: can't write policy\n", argv[2]);
		return 1;
	}
	fclose(f);
	policydb_destroy(&p);
	return 0;
}
