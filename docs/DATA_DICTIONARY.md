# Derived-data dictionary

## Dataset summaries

- `dataset_split_summary.csv`: pre-augmentation image and object totals by split.
- `dataset_source_summary.csv`: source composition by split under the filename rule.
- `class_representation_by_split.csv`: image-containing-class support by split.
- `class_representation_by_source.csv`: training class support by source.
- `fig02_class_support.csv`: plot-ready 52-category support table.

## Evaluation and diagnostics

- `table01_test_performance.csv`: authoritative primary test values from `results.json`.
- `fig03_validation_metrics.csv`: regular and EMA validation AP across epoch indices 0–9.
- `test_ground_truth.coco.json`: 520-image test ground truth and 53-category COCO map, including non-operational parent `fish`.
- `test_predictions.coco.json`: saved confidence-filtered predictions used by corrected diagnostics.
- `confusion_events_corrected.csv`: one-to-one matching events for the complete test-image universe.
- `confusion_matrix_counts_corrected.csv` and `confusion_matrix_normalized_corrected.csv`: corrected class-level matrices.
- `per_image_metrics_corrected.csv`: TP, FP, FN, precision, recall, F1, FN rate, and metric state for all 520 images.
- `vector_analysis_embeddings.csv`: retained 512-dimensional L2-normalized CLIP embeddings. Backbone, package, pretrained weights, and image preprocessing were not recovered.
- `vector_analysis_corrected.csv`: embeddings joined to accepted per-image metrics and UMAP coordinates.
- `neighborhood_enrichment_corrected.csv`: observed/expected neighbor ratios and permutation p values.

## Sensitivity

Files under `data/derived/sensitivity/` compare the original 520-image diagnostic universe with the 519-image set obtained after removing the confirmed train–test duplicate. Metrics from the available evaluator are paired sensitivity values and are not interchangeable with the primary `results.json` evaluator.

## Provenance

`metadata/inaturalist_provenance_manifest.csv` contains public metadata and URLs only. `project_image_filename` is a local project identifier, `operational_class` may contain multiple labels separated by semicolons, `split` records final allocation, and `provenance_status` records whether a unique URL was recovered.
