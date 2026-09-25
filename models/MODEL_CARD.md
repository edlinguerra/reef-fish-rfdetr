# Model card: validation-selected reef-fish RF-DETR Medium

## Intended use

The model was developed to convert sustained SAMP underwater imagery from Bajo de Diez into image-level detections for 51 fish taxon/morphotype classes plus an auxiliary `unidentifiable` category. It supports screening and structured observation generation. It is not a validated estimator of abundance, a counter of unique individuals, or a model demonstrated to transfer across reefs or camera domains.

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
- Proposed archival filename: `reef_fish_rfdetr_medium_v17_epoch4_ema.pth`.
- SHA-256: `522255FB9F18C6148B2206C697E33881A70B7DCAC25F25C20141E09AE74BD073`.

The checkpoint itself is not included in this Git repository. The final held-out test attribution is `AUTHOR CONFIRMED / EVIDENCE FAVORS BEST CHECKPOINT`: the selected state and checkpoint contents were verified, retained notes state that the validation-selected model was tested, and recovered artifacts are consistent with that workflow, but no surviving machine artifact records the checkpoint load immediately before the test pass.

## Evaluation

The primary evaluation used a held-out image-level test set of 520 images and 1,846 annotated objects.

| Metric | Value |
|---|---:|
| mAP@50 | 0.7407811331 |
| mAP@50:95 | 0.5448539545 |
| Precision | 0.7944608346 |
| Recall | 0.650000 |

These are the authoritative values from the final `results.json`. The exact RF-DETR package build and the precision/recall operating-point implementation were not retained. The standalone evaluator included here is useful for paired sensitivity comparisons but is not claimed to reproduce those four values exactly.

## Diagnostics

Corrected diagnostics retain all 520 test images. At IoU ≥ 0.50, the saved-prediction workflow yielded 1,237 correct-class matches, 112 wrong-class matches, and 497 unmatched ground-truth objects. Correct-label assignments were the largest row outcome in 45 of 52 operational categories. Of 490 images containing ground truth, 83 had F1 = 0 and 95 had false-negative rate ≥ 0.75. Low-F1 and high-FN images did not show significant local enrichment in the retained CLIP or UMAP neighborhoods under the specified tests.

## Test-set integrity

The test set is an image-level holdout, not fully source- or sequence-independent. One train–test source-image duplicate was identified. Removing it changed all paired sensitivity metrics by less than 0.00023 and did not change confusion-matrix or CLIP–UMAP conclusions, so the original 520-image primary metrics are retained. Temporal adjacency among some SAMP frames remains a potential source of dependence.

## Deployment

The retained archive script specifies `checkpoint_best_total.pth` and a confidence threshold of 0.50 for six SAMP archive directories. The saved archive output represents 198,965 image records and 81,601 model detections. No raw archive images or checkpoint are distributed in this repository.

## Limitations

- No external reef, site, camera, or environmental-domain validation.
- Taxonomic resolution is operational and includes pooled taxa and morphotypes.
- Unequal class support and reliance on external imagery for uncommon categories.
- Exact RF-DETR build and primary precision/recall operating point unrecovered.
- Original split-allocation rule and grouping seed undocumented.
- Checkpoint weights and raw images are not included here.
- Causes of individual missed detections were not established by the diagnostic analyses.
