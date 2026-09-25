# Reproducibility status

## Verified in this package

- **Table 1:** one-row source table contains 520 test images, 1,846 objects, mAP@50 0.7407811330935539, mAP@50:95 0.5448539544850933, precision 0.7944608346421937, and recall 0.65.
- **Figure 2 numerical Panels A–B:** 8,517/698/520 split counts, 34,068 exported training files, 52 operational categories, and two-source SAMP/iNaturalist class support are retained. Panel C photographs are not public.
- **Figure 3:** exactly ten validation epochs (0–9) are retained; the maximum EMA AP@50:95 is 0.5255759074475391 at epoch index 4. No test metrics enter the selection plot.
- **Figure 4:** the plot table has 52 × 53 class/outcome cells and the ground-truth outcomes sum to 1,846 = 1,237 correct-class + 112 wrong-class + 497 unmatched.
- **Figure 5:** 520 images are retained, including 490 with ground truth, 30 without ground truth, and 59 with no saved detections. The accepted counts are 83 F1-zero images and 95 images with FN rate ≥0.75. Four corrected k=15 neighborhood tests and their accepted ratios/p values are retained.
- **Figure 6 numerical Panel A:** 198,965 image records and 81,601 saved detections. Panel B images/renders are not public.
- **Leakage sensitivity:** the one-image removal produces absolute paired metric changes below 0.00023 with the available evaluator.
- **Provenance:** 2,372 URL-recovered, 319 ambiguous, and 2 URL-missing records among 2,693 final external-image records; 448 additional workbook records are marked not in the final dataset.

`tests/test_public_package.py` passed all of these gates. Python and R scripts passed syntax parsing. The Figure 2 numerical panel, Figures 3–5, and Figure 6 numerical panel were rendered successfully from the curated package during release preparation, then the generated review outputs were removed because this repository distributes code and inputs rather than duplicate figure binaries. Font-discovery warnings on the Windows verification host did not alter the data gates.

## Reproducibility level by component

| Component | Status | Boundary |
|---|---|---|
| Reported numerical results and derived tables | Reproducible from retained public inputs | Primary precision/recall evaluator implementation is not fully recovered. |
| Corrected confusion/per-image diagnostics | Reproducible | Requires the listed R packages; uses public test annotations and saved predictions. |
| CLIP–UMAP diagnostics | Reproducible from retained embeddings | Original CLIP backbone, package, pretrained weights, and image preprocessing are not recovered, so embedding generation is not reproducible. |
| Leakage sensitivity diagnostics | Reproducible | Uses the accepted available evaluator and corrected diagnostic records, not the original headline evaluator. |
| Figures 3–5 | Reproducible | Plotting-only workflows use accepted inputs. |
| Figure 2 | Partially reproducible | Numerical Panels A–B only; Panel C SAMP photographs excluded. |
| Figure 6 | Partially reproducible | Numerical Panel A only; illustrative archive images/renders excluded. |
| Figure 1 | Not reproducible from this public package | Requires source photographs and the saved `_ROW` render. |
| Archive inference | Code/configuration reproducible | Requires the external checkpoint and SAMP archive images. |
| Exact final training | Configuration documented, not byte-identical | Exact launcher, RF-DETR build, optimizer class, and complete environment/split-generation state unrecovered. |

## Commands checked

```text
python tests/test_public_package.py
Rscript scripts/figures/fig03_model_selection.R
Rscript scripts/figures/fig04_error_structure.R
Rscript scripts/figures/fig05_feature_space.R --v3
Rscript scripts/figures/fig02_dataset_composition.R
Rscript scripts/figures/fig06_archive_scale.R
```

No training, inference, COCO reevaluation, UMAP recalculation, or permutation analysis was performed during package verification.
