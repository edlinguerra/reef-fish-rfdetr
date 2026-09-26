# Model card: validation-selected reef-fish RF-DETR Medium

## Intended use

The model converts SAMP underwater imagery from Bajo de Diez into image-level detections for 51 fish taxon/morphotype classes plus an auxiliary `unidentifiable` category. It supports image screening and structured observation generation. The model detects and counts visible fish instances within individual images. It does not perform individual identification or tracking across images. Therefore, detections accumulated across multiple images should not be interpreted as counts of unique individual fish or, without additional ecological validation, as estimates of population abundance. Transfer performance across different reefs or camera domains has not yet been evaluated.

## Architecture and selection

- Architecture: RF-DETR Medium (`RFDETRMedium`).
- Parameters: 33,687,458.
- Encoder: `dinov2_windowed_small`; 12 encoder layers, 4 decoder layers, 300 queries.
- Internal detector resolution: 448 pixels. Dataset export images were 576 × 576 pixels.
- Training: 10 epochs, batch size 1, gradient accumulation 4, EMA enabled.
- Hardware: Dell Precision 7920; one NVIDIA RTX A2000 6 GB GPU.
- Selected state: epoch-index-4 EMA.
- Selection criterion: highest validation COCO AP@50:95 across regular and EMA states.
- Selected validation AP@50:95: 0.5255759074475391.
- Checkpoint filename: `checkpoint_best_total.pth`.
- SHA-256: `522255FB9F18C6148B2206C697E33881A70B7DCAC25F25C20141E09AE74BD073`.

The validation-selected model was used for the held-out test evaluation and archive-scale inference. The checkpoint is not stored in GitHub; it is archived with the versioned reproducibility package at [Zenodo DOI 10.5281/zenodo.22950727](https://doi.org/10.5281/zenodo.22950727).

## Evaluation

The primary evaluation used a held-out image-level test set of 520 images and 1,846 annotated objects.

| Metric | Value |
|---|---:|
| mAP@50 | 0.7407811331 |
| mAP@50:95 | 0.5448539545 |
| Precision | 0.7944608346 |
| Recall | 0.650000 |

These values come from the final RF-DETR test evaluation. The repository does not specify the exact RF-DETR package build or the implementation of the precision/recall operating point. The standalone evaluator supports paired sensitivity comparisons and is not presented as an exact reproduction of the four primary metrics.

## Diagnostics

The corrected diagnostics include all 520 test images. At IoU ≥ 0.50, the saved-prediction workflow produced 1,237 correct-class matches, 112 wrong-class matches, and 497 unmatched ground-truth objects. Correct-label assignments were the largest row outcome in 45 of 52 operational categories. Of 490 images containing ground truth, 83 had F1 = 0 and 95 had false-negative rate ≥ 0.75. Low-F1 and high-FN images did not show significant local enrichment in the supplied CLIP or UMAP neighborhoods under the specified tests.

## Test-set integrity

The test set is an image-level holdout, not fully source- or sequence-independent. One train–test source-image duplicate was identified. Removing it changed all paired sensitivity metrics by less than 0.00023 and did not change the confusion-matrix or CLIP–UMAP conclusions, so the original 520-image primary metrics are reported. Temporal adjacency among some SAMP frames remains a potential source of dependence.

## Deployment

The archive-inference script uses `checkpoint_best_total.pth` and a confidence threshold of 0.50. The saved archive output represents 198,965 image records and 81,601 fish-detection events across images, not 81,601 uniquely identified fish. Raw archive images are not distributed, and the checkpoint is available through Zenodo rather than GitHub.

## Limitations

- No validation on an external reef, site, camera, or environmental domain.
- Taxonomic resolution is operational and includes pooled taxa and morphotypes.
- Unequal class support and use of external reference imagery for uncommon categories.
- The exact RF-DETR build and primary precision/recall operating-point implementation are not documented.
- The original split-allocation rule and grouping seed are not documented.
- Raw images are not included, and model weights are distributed separately through Zenodo.
- The diagnostic analyses characterize the distribution of missed detections but do not establish their causes.
