# Reproducibility scope

## Included numerical records

- **Table 1:** `data/derived/evaluation/table01_test_performance.csv` reports 520 test images, 1,846 objects, mAP@50 0.741, mAP@50:95 0.545, precision 0.794, and recall 0.65.
- **Figure 2 numerical Panels A–B:** the included tables contain 8,517/698/520 split counts, 34,068 exported training files, 52 operational categories, and SAMP/external-reference class support. Panel C photographs are not public.
- **Figure 3:** the validation table contains ten epochs (indices 0–9); the maximum EMA AP@50:95 is 0.526 at epoch index 4. Test metrics are not used in the selection plot.
- **Figure 4:** the plotting table contains 52 × 53 class/outcome cells, and the ground-truth outcomes sum to 1,846 = 1,237 correct-class + 112 wrong-class + 497 unmatched.
- **Figure 5:** the supplied data contain 520 images: 490 with ground truth, 30 without ground truth, and 59 with no saved detections. Among the ground-truth-containing images, 83 have F1 = 0 and 95 have FN rate ≥ 0.75. The four k = 15 neighborhood tests and their ratios and p-values are included.
- **Figure 6 numerical Panel A:** the archive summary contains 198,965 image records and 81,601 saved fish detections. These are detection events across images, not uniquely identified fish or validated population-abundance estimates. Panel B images and renders are not public.
- **Leakage sensitivity:** removal of the single duplicated source image changes each paired metric by less than 0.00023 with the repository evaluator.
- **External-image provenance:** the manifest contains 2,372 `URL_RECOVERED`, 319 `AMBIGUOUS_MATCH`, and 2 `URL_MISSING` records among 2,693 final external-image records; 448 additional workbook records are marked `NOT_IN_FINAL_DATASET`.

`tests/test_public_package.py` checks these values, dimensions, and exclusions using the Python standard library.

## Reproducibility by component

| Component | Reproducibility provided | Boundary |
|---|---|---|
| Reported numerical results and derived tables | Included source tables and automated consistency checks | The repository does not include the RF-DETR evaluator implementation that generated the primary precision and recall values. |
| Corrected confusion/per-image diagnostics | Complete R workflow using included test annotations and saved predictions | Requires the R packages listed under `environment/`. |
| CLIP–UMAP diagnostics | Complete downstream workflow from the supplied 512-dimensional embeddings | The CLIP backbone, package, pretrained weights, and image preprocessing are not documented, so the embeddings cannot be regenerated from images. |
| Leakage-sensitivity diagnostics | Complete paired workflow from included evaluation and diagnostic records | Uses the repository evaluator rather than the evaluator that generated the primary RF-DETR metrics. |
| Figures 3–5 | Complete plotting workflows from included inputs | Plotting does not rerun model inference or the original embedding extraction. |
| Figure 2 | Numerical Panels A–B | Panel C SAMP photographs are not redistributed. |
| Figure 6 | Numerical Panel A | Illustrative archive images and saved renders are not redistributed. |
| Figure 1 | Caption only | Source photographs and the saved `_ROW` render are not redistributed as reproduction inputs. |
| Archive inference | Portable code and configuration | Requires the SAMP archive images and the checkpoint archived in Zenodo. |
| Final training | Documented architecture and training configuration | The repository does not provide a standalone final-run launcher, exact RF-DETR package build, optimizer class, original split-allocation procedure, or complete random-state context for byte-identical retraining. |

The validation-selected checkpoint is archived with the versioned reproducibility package at [Zenodo DOI 10.5281/zenodo.22950727](https://doi.org/10.5281/zenodo.22950727).

## Commands

```text
python tests/test_public_package.py
Rscript scripts/figures/fig03_model_selection.R
Rscript scripts/figures/fig04_error_structure.R
Rscript scripts/figures/fig05_feature_space.R --v3
Rscript scripts/figures/fig02_dataset_composition.R
Rscript scripts/figures/fig06_archive_scale.R
```

These commands validate the public package and regenerate the supported figure panels. They do not rerun training, archive inference, the primary RF-DETR evaluation, CLIP embedding extraction, or analyses that are represented by supplied derived outputs only.
