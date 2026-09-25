# License scope

This repository uses separate licenses for author-generated software and author-generated research data. A license applies only where the project authors hold the rights required to grant it and only where a file does not state different terms.

## Source code and scripts

Author-generated source code and scripts are licensed under the [PolyForm Noncommercial License 1.0.0](PolyForm-Noncommercial-1.0.0.txt), unless otherwise noted. This includes the author-generated code under `scripts/`, figure-production scripts, diagnostic and evaluation utilities, and repository tests.

PolyForm permits the noncommercial uses described in its canonical terms, including permitted inspection, modification, and distribution. Copies and redistributions must preserve the license terms or canonical URL and any `Required Notice:` supplied with the software. The project notice is in [`../NOTICE`](../NOTICE).

Commercial use is not permitted under this license.

## Derived data and metadata

Author-generated derived datasets, tables, metadata, provenance manifests, ontology tables, configuration records, plot-ready data, and other eligible research outputs are licensed under [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](CC-BY-NC-SA-4.0.txt), unless otherwise noted. This applies to public author-generated material under `data/derived/`, `metadata/`, `config/`, and `figures/data/` only to the extent that the authors have authority to license it. Reuse requires attribution, is limited to non-commercial purposes, and derivative material must use the same license where the CC BY-NC-SA terms apply.

The CC license covers the project-authored compilation and metadata, not the third-party works, photographs, websites, or other resources to which a record or URL may refer.

## Excluded or separately governed material

The repository-wide licenses do not automatically cover:

- third-party photographs, including iNaturalist and other externally sourced images;
- SAMP photographs or image-dependent renders unless explicitly identified as released under a stated license;
- institutional or project logos, including the ENES Mérida and cam2model logos;
- graphical-abstract or figure-preview images containing photographic material unless accompanied by an explicit rights statement;
- `checkpoint_best_total.pth`, any archival alias of that checkpoint, or other trained model weights unless accompanied by an explicit license;
- upstream RF-DETR base weights, RF-DETR implementation code, third-party software, libraries, or dependencies; or
- any file that carries its own license or third-party notice.

Third-party photographs are not redistributed by this project. Provenance manifests provide metadata and source URLs only; they do not grant rights to the linked content.

Model checkpoints and weights are not covered by PolyForm Noncommercial 1.0.0 or CC BY-NC-SA 4.0 unless an explicit license is supplied with them. See [`../models/README.md`](../models/README.md).

## Attribution and citation

Reuse must comply with the attribution and notice terms of the applicable license. Preserve the project notice in [`../NOTICE`](../NOTICE), including acknowledgement of PAPIIT-UNAM project IN208124 and the manuscript authors/project source as appropriate.

Source code and version history are maintained at [GitHub](https://github.com/edlinguerra/reef-fish-rfdetr). The project's single versioned reproducibility package is assigned Zenodo DOI [10.5281/zenodo.22950727](https://doi.org/10.5281/zenodo.22950727). Cite the relevant repository release and published article when reusing these materials.
