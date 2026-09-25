# README v3 design notes

## Scope

`README_v3.md` is an author-review candidate derived from `README_v2.md`. The existing `README.md` remains unchanged. This targeted revision incorporates the final author list and CRediT statement; it does not change model results, repository claims, graphical assets, funding, data-availability language, or reproducibility statements.

## Visual assets

The following existing files are embedded without modification:

| Asset | Source dimensions | README display width | Purpose |
|---|---:|---:|---|
| `docs/assets/ENES_Merida.jpg` | 814 × 476 px | 170 px | Institutional identity; visually secondary to the manuscript title. |
| `docs/assets/cam2model_2.PNG` | 1024 × 1024 px | 105 px | Project/workflow identity; visually secondary to the manuscript title. |
| `docs/assets/GA_draft_v5.png` | 2500 × 1000 px | 1000 px | Accepted graphical-abstract preview below the title and authorship block. |

Accessible alt text is supplied for every embedded asset. No logo or graphical-abstract file was downloaded, recreated, resized, recolored, or otherwise edited.

An image-metadata check found no GPS information in any of the three files. The ENES Mérida JPEG and cam2model PNG retain nonspatial creation timestamps from the author-provided originals; these were not stripped because the task requires using the exact existing assets.

## Authorship and affiliation

`README_v3.md` incorporates the author-confirmed final manuscript list of 12 authors, in the supplied order, and the corresponding full-name CRediT statement. Quetzalli Hernández is not included in either manuscript authorship or the CRediT statement. `CITATION_v2.cff` carries the same 12-author order for both the software record and preferred manuscript citation, without inferred ORCIDs, email addresses, affiliations, or corresponding-author status.

The project affiliation is stated without assigning it to individual authors:

`Escuela Nacional de Estudios Superiores, Unidad Mérida, Universidad Nacional Autónoma de México (UNAM), Mérida, Yucatán, Mexico`

The author list and contribution roles were supplied directly and were not inferred from the grant-recipient information or author position.

## Funding

The dedicated Funding section inserts the confirmed statement verbatim:

> This research was supported by the Dirección General de Asuntos del Personal Académico (DGAPA) of the Universidad Nacional Autónoma de México (UNAM) through the Programa de Apoyo a Proyectos de Investigación e Innovación Tecnológica (PAPIIT), under grant number IN208124, awarded to Edlin Guerra-Castro.

## Navigation and hierarchy

The top navigation links to these stable Markdown headings:

- Overview
- Scientific record
- Repository contents
- Quick verification
- Reproducing figures
- Diagnostic workflows
- Model availability
- Data availability
- Funding
- Citation
- License
- Status

A concise “Where to start” table connects common tasks to `tests/`, `scripts/figures/`, `scripts/diagnostics/`, `models/MODEL_CARD.md`, `metadata/`, and `docs/`.

Three restrained badges indicate Python 3.11, R analysis, and passed reproducibility checks. No DOI, license, journal, acceptance, or publication badge is included.

## Scientific and availability boundaries retained

- All RF-DETR, dataset, test, performance, and archive-scale values are unchanged from the current README and controlling records.
- The test set remains described as an image-level holdout rather than fully source- or sequence-independent.
- The duplicate-image sensitivity result remains below 0.00023 for the paired available-evaluator metrics.
- Diagnostic counts remain explicitly distinct from the primary RF-DETR evaluator.
- Third-party photographs remain non-redistributed; public provenance metadata and recovered URLs are described instead.
- Raw SAMP imagery remains restricted pending redistribution authorization.
- The checkpoint remains external to GitHub and awaits a separate DOI-bearing deposit after license review.
- No Mendeley Data, Zenodo, article DOI, or public-repository record is represented as already existing.

## Remaining visual-rights questions

Before making the repository public, the authors should confirm permission to distribute the ENES Mérida institutional logo, the cam2model logo, and the graphical-abstract preview through the repository. The graphical abstract contains SAMP-derived visual material and an existing saved detector render; embedding it for author review does not itself resolve public redistribution rights. These assets are intentionally limited to `docs/assets/` and are not covered by any future code license unless explicitly stated.
