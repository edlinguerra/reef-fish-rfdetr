# Script provenance

## Included workflows

| Public script | Project source or basis | Public-package change | Scientific status |
|---|---|---|---|
| `scripts/inference/infer_archive.py` | `infer_lotes_v2.py` | Replaced workstation paths with required arguments; retained RF-DETR Medium, checkpoint input, default threshold 0.50, six-directory scan, category mapping, and resumable COCO-like output. | Authoritative archive workflow, path-sanitized. |
| `scripts/evaluation/align_predictions_to_gt.py` | Same filename in v17 scripts | Copied unchanged. | Retained prediction-alignment utility. |
| `scripts/evaluation/evaluate_coco_predictions.py` | Same filename in v17 scripts | Copied unchanged. | Available sensitivity evaluator; not the original headline evaluator. |
| `scripts/diagnostics/matriz_confusion_corrected.R` | Accepted corrected script | Replaced script-local working-directory assumptions with `--data-dir` and `--output-dir`. Matching logic and thresholds unchanged. | Authoritative corrected confusion workflow. |
| `scripts/diagnostics/vector_analysis_corrected.R` | Accepted corrected script | Replaced script-local paths with arguments. Embedding, UMAP, matching, metrics, and permutation logic unchanged. | Authoritative corrected vector workflow. |
| `scripts/leakage_sensitivity/test_leakage_sensitivity_diagnostics.R` | Accepted sensitivity script | Removed a workstation library path and added portable data/output arguments. Analytical logic unchanged. | Authoritative accepted sensitivity workflow. |
| `scripts/figures/fig03_model_selection.R` | Accepted Figure 3 table and production script | Reads the published validation-only CSV instead of private run logs; preserves the epoch-index-4 selection gate. | Public plot reproduction. |
| `scripts/figures/fig04_error_structure.R` | Accepted Figure 4 plot-ready tables | Uses public plot-ready matrix and outcome tables; no matching is recomputed. | Public plot reproduction. |
| `scripts/figures/fig05_feature_space.R` | Accepted Figure 5 v3 script | Replaced project-local paths with public data/output arguments. | Public plot reproduction; no UMAP or permutation rerun. |
| `scripts/figures/fig02_dataset_composition.R` | Accepted Figure 2 numerical inputs | Reproduces public-safe Panels A–B only. | Partial reproduction because Panel C photographs are excluded. |
| `scripts/figures/fig06_archive_scale.R` | Accepted Figure 6 scale values | Reproduces public-safe Panel A only. | Partial reproduction because illustrative photographs/renders are excluded. |

SHA-256 checksums of the released scripts should be generated for each tagged release. The initial Git commit supplies immutable version control for the present files.

## Deliberately excluded scripts and artifacts

- The retained edited three-epoch training script was excluded because it targets a separate `output_1` run and does not reproduce the authoritative ten-epoch v17 training run.
- No exact final-run launcher was recovered. Verified configuration is transcribed in `config/` without claiming byte-identical retraining.
- Original uncorrected `matriz_confusion.R` and `vector_analysis.R` were excluded because the accepted corrected scripts supersede them.
- Historical model-version scripts, `output_1`, exploratory notebooks, checkpoint-comparison utilities, and temporary debugging code were excluded.
- Figure 1 production code was excluded because it requires non-redistributed photographs and a saved image render. Its caption remains for manuscript traceability.
- Full Figure 2 and Figure 6 assembly scripts were replaced by public-safe numerical-panel scripts because their illustrative image assets are not redistributed.
- `cam2model` source code was not found among the accessible project files and is therefore not represented as included software.
- No model checkpoint, pretrained-weight file, raw image, mixed dataset export, or full archive prediction JSON is included.

## Non-equivalence warning

The standalone evaluation script is not the implementation that generated the four primary `results.json` metrics. The exact RF-DETR package build and precision/recall operating-point method are unrecovered. The public code supports inspection, corrected diagnostics, paired sensitivity, and plot reproduction without claiming byte-identical headline evaluation or retraining.
