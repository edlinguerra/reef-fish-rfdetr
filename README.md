# Reef-fish RF-DETR reproducibility package

This repository supports the manuscript **“Scaling spatiotemporal reef-fish monitoring with computer vision in the southern Gulf of Mexico.”** It contains the public-safe code, configuration, ontology, evaluation records, corrected diagnostics, leakage sensitivity outputs, plot-ready tables, and figure scripts needed to inspect the reported results.

The package is deliberately curated. It does **not** contain raw SAMP photographs, third-party photographs, mixed Roboflow image exports, model checkpoints, private workbooks, historical runs, local environments, or temporary files.

## Scientific record

- Final architecture: RF-DETR Medium, 33,687,458 parameters.
- Operational ontology: 51 fish taxon/morphotype classes plus `unidentifiable` (52 evaluated categories). The COCO parent `fish` is non-operational.
- Export preprocessing: 576 × 576 pixels; detector resolution: 448 pixels.
- Training: 10 epochs on one NVIDIA RTX A2000 6 GB GPU in a Dell Precision 7920; approximately 17 h.
- Model selection: epoch-index-4 EMA, chosen by maximum validation COCO AP@50:95 (0.5255759074475391).
- Held-out image-level test: 520 images, 1,846 ground-truth objects.
- Reported test metrics: mAP@50 0.7407811331; mAP@50:95 0.5448539545; precision 0.7944608346; recall 0.650000.
- Archive application: 198,965 image records and 81,601 saved detections at confidence threshold 0.50. Detections are model outputs, not counts of unique fish.

The validation-selected checkpoint is `checkpoint_best_total.pth`. It is not included here. Its attribution to the final held-out test is author-confirmed and consistent with the retained run record; the archive-inference script directly specifies the same checkpoint filename. See [models/MODEL_CARD.md](models/MODEL_CARD.md).

## Test-set qualification

The test partition is a held-out **image-level** set, not a fully source- or sequence-independent set. A post hoc audit found one train–test source-image duplicate. Removing it changed every paired metric produced by the available sensitivity evaluator by less than 0.00023 and did not change the confusion-matrix or CLIP–UMAP interpretation. The original 520-image RF-DETR metrics remain the primary reported results. Some SAMP images are temporally adjacent across splits; this is potential dependence, not exact leakage.

## Repository contents

| Directory | Contents |
|---|---|
| `config/` | Operational class map, preprocessing/augmentation settings, detector/training configuration, and analysis thresholds. |
| `data/derived/` | Dataset summaries, primary test table, corrected diagnostic outputs, retained embeddings, and leakage sensitivity outputs. |
| `metadata/` | Public iNaturalist provenance manifest and coverage notes. No image pixels are included. |
| `scripts/` | Portable inference, evaluation, corrected diagnostics, and public-safe figure scripts. |
| `figures/data/` | Plot-ready figure inputs and archive-scale summary. |
| `figures/captions/` | Accepted draft captions. |
| `models/` | Model card and checkpoint acquisition/deposit placeholder. |
| `tests/` | Integrity checks for headline values and figure inputs. |
| `docs/` | Provenance, release scan, and reproducibility-status records. |

## Quick verification

From the repository root:

```bash
python tests/test_public_package.py
```

The test checks Figure 3 selection, Figure 4 totals and matrix dimensions, Figure 5 image and neighborhood counts, Table 1 values, Figure 2 numerical inputs, Figure 6 archive totals, ontology size, and iNaturalist provenance coverage.

R figure scripts require the packages listed in `environment/R_PACKAGES.md`. Examples:

```bash
Rscript scripts/figures/fig03_model_selection.R
Rscript scripts/figures/fig04_error_structure.R
Rscript scripts/figures/fig05_feature_space.R --v3
Rscript scripts/figures/fig02_dataset_composition.R
Rscript scripts/figures/fig06_archive_scale.R
```

Figures 2 and 6 are only partially reproducible from the public repository because their photographic panels use SAMP images or saved image renders that are not redistributed. Their numerical panels are fully represented. Figure 1 is captioned but cannot be regenerated without its source photographs and saved render.

## Diagnostic workflows

The corrected confusion and vector analyses use all 520 test images, including images with zero saved detections. Default commands write to `outputs/`:

```bash
Rscript scripts/diagnostics/matriz_confusion_corrected.R
Rscript scripts/diagnostics/vector_analysis_corrected.R
Rscript scripts/leakage_sensitivity/test_leakage_sensitivity_diagnostics.R
```

These workflows use a diagnostic confidence filter of 0.25 and one-to-one matching at IoU ≥ 0.50. The retained saved predictions already have scores of approximately 0.50 or higher. Diagnostic TP/FP/FN counts are not the numerators of the original RF-DETR headline precision and recall.

## Evaluation caveat

`scripts/evaluation/evaluate_coco_predictions.py` is the retained standalone evaluator used for paired sensitivity calculations. It is **not** represented as the exact RF-DETR implementation that produced the four headline values in `results.json`; the exact RF-DETR package build and precision/recall operating-point implementation were not retained.

## Image and data availability

- iNaturalist and other externally sourced photographs are not redistributed. `metadata/inaturalist_provenance_manifest.csv` links project identifiers to original URLs where a unique match was recovered.
- The manifest recovers a unique valid URL for 2,372 of 2,693 final external-image records (88.08%); 319 are ambiguous and 2 are unmatched.
- Raw SAMP photographs are not included pending confirmation of institutional and project redistribution rights.
- The checkpoint and large archive-scale prediction record are intended for a DOI-bearing data deposit once author approval and rights review are complete.

Consult linked third-party sources under their current terms. A URL does not itself establish creator attribution or license.

## Citation and license

`CITATION.cff` contains bibliographic placeholders until the article author list, journal details, DOI, and repository URL are final. Source-code licensing is not yet assigned; see `LICENSE_PENDING.md`. Third-party data and images are never covered by a future code license.

## Status

This is the initial curated public-package implementation. See [docs/REPRODUCIBILITY_STATUS.md](docs/REPRODUCIBILITY_STATUS.md) and [docs/RELEASE_SCAN_REPORT.md](docs/RELEASE_SCAN_REPORT.md) before public release.
