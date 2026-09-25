# External image provenance

The project does not redistribute any photograph recorded in its iNaturalist source category, even where an individual image license might permit redistribution. The accompanying `inaturalist_provenance_manifest.csv` releases metadata and source links only.

The manifest covers 2,693 final external-image source records across training, validation, and held-out test splits:

| Outcome | Records |
|---|---:|
| Unique valid source URL recovered | 2,372 |
| Ambiguous one-to-one match | 319 |
| URL missing | 2 |
| Total | 2,693 |

Coverage is **88.08% (2,372/2,693)**. Of the recovered records, 2,264 point directly to an iNaturalist domain or its open-data host and 108 point to other external domains retained in the source workbook. The project category name `iNaturalist` is therefore a dataset provenance category, not a guarantee that every recovered URL is hosted by iNaturalist.

The source URL alone does not establish creator attribution, license, observation identity, current accessibility, or permission to redistribute. Creator and license fields remain blank unless documented. Users should consult the original URL under the source site's current terms.

Allowed provenance states are `URL_RECOVERED`, `URL_MISSING`, `AMBIGUOUS_MATCH`, and `NOT_IN_FINAL_DATASET`.
