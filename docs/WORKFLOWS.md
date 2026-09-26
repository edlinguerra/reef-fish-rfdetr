# Reproducibility workflows

This document maps the public scripts to the manuscript analyses and identifies the inputs required for each workflow. Commands are run from the repository root unless noted otherwise.

## Evaluation and diagnostics

| Workflow | Public script | Purpose | Reproducibility boundary |
|---|---|---|---|
| Prediction alignment | `scripts/evaluation/align_predictions_to_gt.py` | Align saved test predictions to the 520-image COCO ground-truth universe. | Operates on the included test metadata and predictions. |
| Paired sensitivity evaluation | `scripts/evaluation/evaluate_coco_predictions.py` | Compare the original 520-image set with the 519-image set after removal of the train–test duplicate. | Uses a separate evaluator from the RF-DETR implementation that generated the four primary test metrics. |
| Corrected confusion analysis | `scripts/diagnostics/matriz_confusion_corrected.R` | Reproduce corrected class assignments and per-image TP, FP, and FN values for all 520 test images. | Uses the documented confidence filter and one-to-one matching at IoU ≥ 0.50. |
| Corrected vector analysis | `scripts/diagnostics/vector_analysis_corrected.R` | Join per-image metrics to the included 512-dimensional embeddings, project them with UMAP, and run the specified neighborhood tests. | Reproduces the downstream analysis from supplied embeddings; it does not regenerate CLIP embeddings from images. |
| Leakage-sensitivity diagnostics | `scripts/leakage_sensitivity/test_leakage_sensitivity_diagnostics.R` | Reproduce the corrected diagnostic comparison after removal of the duplicated source image. | Uses the repository evaluator and included diagnostic records. |

## Figure workflows

| Figure | Public script | Coverage |
|---|---|---|
| Figure 2 | `scripts/figures/fig02_dataset_composition.R` | Numerical Panels A–B; Panel C photographs are not redistributed. |
| Figure 3 | `scripts/figures/fig03_model_selection.R` | Validation-only regular and EMA model-selection curves. |
| Figure 4 | `scripts/figures/fig04_error_structure.R` | Corrected class-level matrix and ground-truth outcomes. |
| Figure 5 | `scripts/figures/fig05_feature_space.R` | Included UMAP coordinates, per-image metrics, and neighborhood-enrichment summary. |
| Figure 6 | `scripts/figures/fig06_archive_scale.R` | Numerical Panel A; illustrative SAMP images and saved renders are not redistributed. |

Figure 1 requires non-redistributed source photographs and its saved detector render, so it is not generated from this repository.

## Archive inference

`scripts/inference/infer_archive.py` provides the archive-inference workflow with command-line paths, RF-DETR Medium configuration, a default confidence threshold of 0.50, recursive image scanning, category mapping, and resumable COCO-like output. Running it requires the SAMP archive images and the validation-selected checkpoint.

The checkpoint `checkpoint_best_total.pth` is not stored in GitHub. It is archived with the versioned reproducibility package at [Zenodo DOI 10.5281/zenodo.22950727](https://doi.org/10.5281/zenodo.22950727).

## Training configuration

The final ten-epoch training settings are documented in [`../config/training.yaml`](../config/training.yaml) and [`../config/final_model_config.yaml`](../config/final_model_config.yaml). The repository does not include a standalone launcher for byte-identical retraining, and it does not specify the exact RF-DETR package build, optimizer class, original split-allocation procedure, or complete random-state context. These limits do not affect reproduction of the included evaluation records, corrected diagnostics, sensitivity analysis, or figure panels.

## Companion workflow

[cam2model](https://github.com/arturoSP/cam2model) is a companion image-management and training-data preparation workflow maintained separately from this repository.

