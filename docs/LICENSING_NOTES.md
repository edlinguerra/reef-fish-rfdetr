# Licensing notes

## Implemented framework

- Author-generated source code and scripts: **PolyForm Noncommercial License 1.0.0**.
- Author-generated derived datasets, metadata, manifests, ontology tables, configuration records, and plot-ready data: **CC BY-NC-SA 4.0**, unless otherwise noted and only where the authors hold the necessary rights.
- Project attribution: preserve the `NOTICE` file and acknowledge PAPIIT-UNAM project IN208124 and the manuscript authors/project source as appropriate.

The root `LICENSE` routes users to the applicable terms. `LICENSES/README.md` defines the material-by-material scope.

## Canonical-text verification

The unmodified plain-text licenses were retrieved from the official publishers on 2026-09-24:

| License file | Official source | SHA-256 of retrieved text |
|---|---|---|
| `LICENSES/PolyForm-Noncommercial-1.0.0.txt` | <https://polyformproject.org/licenses/noncommercial/1.0.0.txt> | `FFCCA38841ADB694B6F380647E15F17C446A4D1656FED51A1E2041D064C94CC8` |
| `LICENSES/CC-BY-NC-SA-4.0.txt` | <https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode.txt> | `E66C269D4819AAAB34B49EF5220C4DDAB6756F21BB5180761A4EB8561F2B7BBD` |

The files were not rewritten, summarized, or customized. Repository-specific scope and attribution statements are kept outside the canonical texts.

## Exclusions and separate rights

The blanket licenses exclude third-party photographs, externally sourced imagery, institutional/project logos, SAMP photographs without separate authorization, image-dependent renders without explicit clearance, upstream RF-DETR implementation/base weights, third-party software, and files carrying their own terms.

The trained checkpoint `checkpoint_best_total.pth`, any archival alias, upstream RF-DETR implementation code, and base weights are not covered by the repository-wide code or data licenses. A checkpoint or model weight may be reused only when an explicit license is supplied with it.

The public provenance manifest may be released under CC BY-NC-SA 4.0 as a project-authored metadata compilation where the authors have the relevant rights. The license does not extend to photographs or webpages linked from the manifest.

The retained COCO files `data/derived/evaluation/test_ground_truth.coco.json` and `data/derived/evaluation/test_predictions.coco.json` contain an export-level `CC BY 4.0` metadata statement inherited from the Roboflow export. That embedded statement was not modified. The repository's CC BY-NC-SA 4.0 notice applies only to author-generated derived content where the authors have licensing authority and does not override previously applicable terms or grant rights to underlying third-party photographs. `scripts/inference/infer_archive.py` preserves any COCO license metadata supplied in its input; this behavior does not relicense the referenced images.

The project's single versioned reproducibility package is assigned Zenodo DOI [10.5281/zenodo.22950727](https://doi.org/10.5281/zenodo.22950727). The archived record identifies the included materials and any material-specific terms supplied with them.
