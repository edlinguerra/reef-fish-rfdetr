<div align="center">
  <img src="docs/assets/ENES_Merida.jpg" alt="Escuela Nacional de Estudios Superiores Unidad Mérida, UNAM logo" width="170">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/assets/cam2model_2.PNG" alt="cam2model for SAMP project logo" width="105">

  <h1>Scaling spatiotemporal reef-fish monitoring with computer vision in the southern Gulf of Mexico</h1>

  <p><strong>reef-fish-rfdetr</strong></p>
  <p><em>Reproducible computer-vision workflow for spatiotemporal reef-fish monitoring</em></p>

  <p>
    <img src="https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white" alt="Python 3.11">
    <img src="https://img.shields.io/badge/R-analysis-276DC3?logo=r&logoColor=white" alt="R analysis">
    <img src="https://img.shields.io/badge/reproducibility-checks%20passed-2E7D32" alt="Reproducibility checks passed">
    <a href="https://doi.org/10.5281/zenodo.22950727"><img src="https://zenodo.org/badge/DOI/10.5281/zenodo.22950727.svg" alt="Zenodo DOI 10.5281/zenodo.22950727"></a>
  </p>
</div>

## Authors and affiliation

**Authors:** Edlin José Guerra Castro; Arturo Sanchez-Porras; Fernando Nuno Diaz Marques Simoes; Ángela Randazzo-Eisemann; Ilse Ruiz-Mercado; Vanesa Papiol; Víctor Eduardo Gómez-Bretón; Damián Alejandro Cedillo-Reyna; Alan Javier Ramírez-Menéndez; Miguel Ángel Plata-Díaz; Rodrigo Contreras-Chávez; Ximena Isabel Pérez-Meza

**Project affiliation:** Escuela Nacional de Estudios Superiores, Unidad Mérida, Universidad Nacional Autónoma de México (UNAM), Mérida, Yucatán, Mexico

**Repository:** [https://github.com/edlinguerra/reef-fish-rfdetr](https://github.com/edlinguerra/reef-fish-rfdetr)

**Repository maintainer:** Edlin José Guerra Castro

<div align="center">
  <img src="docs/assets/GA_draft_v5.png" alt="Graphical abstract showing sustained underwater monitoring, RF-DETR structured detections, and archive-scale reef-fish monitoring" width="1000">
</div>

**Reproducibility:** Figures 3–5 can be regenerated from the included inputs; the numerical panels of Figures 2 and 6 can be regenerated without the restricted photographic assets. See [reproducibility documentation](docs/REPRODUCIBILITY_STATUS.md).

[Overview](#overview) · [Scientific record](#scientific-record) · [Repository contents](#repository-contents) · [Quick verification](#quick-verification)  
[Reproducing figures](#reproducing-figures) · [Diagnostic workflows](#diagnostic-workflows) · [Model availability](#model-availability) · [Data availability](#data-availability)  
[Funding](#funding) · [Citation](#citation) · [License](#license)

## Overview

Sustained autonomous underwater monitoring can extend temporal coverage and spatial reach, but repeated sampling can generate image volumes that exceed manual interpretation capacity. Converting those images into taxonomically resolved observations becomes a processing bottleneck as monitoring intensifies.

This repository contains the code, configuration, derived evaluation records, corrected diagnostics, leakage-sensitivity outputs, and figure inputs for an RF-DETR workflow that detects reef-fish taxa and morphotypes. The workflow supports the interpretation of sustained underwater-image collections while keeping model detections distinct from counts of unique fish or validated ecological estimates.

Complementary workflow support is provided by [cam2model](https://github.com/arturoSP/cam2model), a companion project developed by Edlin José Guerra Castro and Arturo Sanchez-Porras for organizing reproducible image-to-model processing.

### Where to start

| Goal | Location |
|---|---|
| Run repository checks | [`tests/`](tests/) |
| Generate reproducible figure panels | [`scripts/figures/`](scripts/figures/) |
| Inspect corrected diagnostics | [`scripts/diagnostics/`](scripts/diagnostics/) |
| Inspect model metadata and limitations | [`models/MODEL_CARD.md`](models/MODEL_CARD.md) |
| Inspect external-image provenance | [`metadata/`](metadata/) |
| Inspect reproducibility documentation | [`docs/`](docs/) |

## Scientific record

- Final architecture: RF-DETR Medium, 33,687,458 parameters.
- Operational ontology: 51 fish taxon/morphotype classes plus `unidentifiable` (52 evaluated categories). The COCO parent `fish` is non-operational.
- Export preprocessing: 576 × 576 pixels; detector resolution: 448 pixels.
- Training: 10 epochs on one NVIDIA RTX A2000 6 GB GPU in a Dell Precision 7920; approximately 17 h.
- Model selection: epoch-index-4 EMA, chosen by maximum validation COCO AP@50:95 (0.5255759074475391).
- Held-out image-level test: 520 images and 1,846 ground-truth objects.
- Reported test metrics: mAP@50 0.7407811331; mAP@50:95 0.5448539545; precision 0.7944608346; recall 0.650000.
- Archive application: 198,965 image records and 81,601 saved detections at confidence threshold 0.50. Detections are model outputs, not counts of unique fish.

### Test-set qualification

The test partition is a held-out **image-level** set, not a fully source- or sequence-independent set. One source image occurred in both the training and test partitions. Excluding that image in a paired sensitivity analysis changed every evaluated metric by less than 0.00023 and did not change the confusion-matrix or CLIP–UMAP interpretation. The original 520-image RF-DETR metrics remain the primary reported results. Some SAMP images are temporally adjacent across splits, creating potential dependence without exact image duplication.

## Repository contents

| Directory | Contents |
|---|---|
| `config/` | Operational class map, preprocessing and augmentation settings, detector/training configuration, and analysis thresholds. |
| `data/derived/` | Dataset summaries, primary test table, corrected diagnostic outputs, CLIP embeddings, and leakage-sensitivity outputs. |
| `metadata/` | Public external-image provenance manifest and coverage notes; no third-party image pixels. |
| `scripts/` | Portable inference, evaluation, corrected diagnostics, leakage sensitivity, and figure workflows. |
| `figures/data/` | Plot-ready figure inputs and archive-scale summary. |
| `figures/captions/` | Manuscript figure captions. |
| `models/` | Model card and checkpoint metadata. |
| `tests/` | Automated checks for reported values and figure inputs. |
| `docs/` | Reproducibility, data availability, provenance, design, and licensing documentation. |

This repository excludes raw SAMP photographs, third-party photographs, mixed Roboflow image exports, model checkpoints, working workbooks, local environments, and temporary files.

## Quick verification

From the repository root:

```bash
python tests/test_public_package.py
```

The command checks the values and dimensions used in Figures 2–6 and Table 1, together with ontology size, leakage-sensitivity results, and external-image provenance coverage.

## Reproducing figures

R package versions are listed in [`environment/r-package-versions.txt`](environment/r-package-versions.txt). Run the figure scripts from the repository root:

```bash
Rscript scripts/figures/fig03_model_selection.R
Rscript scripts/figures/fig04_error_structure.R
Rscript scripts/figures/fig05_feature_space.R --v3
Rscript scripts/figures/fig02_dataset_composition.R
Rscript scripts/figures/fig06_archive_scale.R
```

Figures 3–5 are reproducible from the included inputs. Figures 2 and 6 are partially reproducible because their photographic panels use SAMP images or saved image renders that are not redistributed as figure-reproduction data. Their numerical panels are fully represented. Figure 1 cannot be regenerated without its source photographs and saved render.

## Diagnostic workflows

The corrected confusion and vector analyses retain all 520 test images, including images with zero saved detections. Default commands write to `outputs/`:

```bash
Rscript scripts/diagnostics/matriz_confusion_corrected.R
Rscript scripts/diagnostics/vector_analysis_corrected.R
Rscript scripts/leakage_sensitivity/test_leakage_sensitivity_diagnostics.R
```

The diagnostic workflow applies a confidence threshold of 0.25 and one-to-one matching at IoU ≥ 0.50. The saved predictions have scores of approximately 0.50 or higher. Diagnostic TP, FP, and FN counts are separate from the numerators used for the reported RF-DETR precision and recall.

The standalone evaluator in `scripts/evaluation/evaluate_coco_predictions.py` supports the paired leakage-sensitivity calculations. It uses a separate evaluation workflow from the RF-DETR evaluation that produced the four reported test metrics and should not be used to reproduce those headline values.

## Model availability

The validation-selected checkpoint (`checkpoint_best_total.pth`) contains the epoch-index-4 EMA model used for the manuscript analyses and archive-scale inference. The checkpoint is archived with the project's Zenodo release and is not stored in this GitHub repository.

Model documentation is provided in [`models/README.md`](models/README.md) and [`models/MODEL_CARD.md`](models/MODEL_CARD.md). Model weights are accompanied by their applicable license terms.

## Data availability

The reproducibility materials associated with this repository are archived in Zenodo at **[10.5281/zenodo.22950727](https://doi.org/10.5281/zenodo.22950727)**. The archive includes the versioned repository snapshot, additional derived outputs, and the validation-selected model checkpoint. Third-party reference photographs and raw SAMP image collections are not redistributed.

GitHub provides the living source repository, version history, code, scripts, configuration, documentation, tests, and small reproducibility data already tracked in the repository. Zenodo provides the immutable `v1.0.0` reproducibility release, including the source snapshot, additional derived outputs, and the validation-selected RF-DETR checkpoint.

[`metadata/inaturalist_provenance_manifest.csv`](metadata/inaturalist_provenance_manifest.csv) provides project identifiers, operational labels, split membership, match status, and recovered source URLs where unique mappings were available. The manifest links 2,372 of 2,693 final external-image records (88.08%) to a unique valid URL; 319 mappings are ambiguous and 2 records lack a URL.

Users should consult linked third-party sources under their current terms. A retained URL does not by itself establish creator attribution, license, continued availability, or permission to redistribute an image. See [`docs/DATA_AVAILABILITY.md`](docs/DATA_AVAILABILITY.md) and [`metadata/EXTERNAL_IMAGE_PROVENANCE.md`](metadata/EXTERNAL_IMAGE_PROVENANCE.md).

## Author contributions

**Edlin José Guerra Castro:** Conceptualization, Data curation, Formal analysis, Funding acquisition, Project administration, Writing – original draft, Writing – review & editing.

**Arturo Sanchez-Porras:** Software, Writing – review & editing.

**Fernando Nuno Diaz Marques Simoes:** Conceptualization, Funding acquisition, Writing – review & editing.

**Ángela Randazzo-Eisemann:** Supervision, Validation, Writing – review & editing.

**Ilse Ruiz-Mercado:** Conceptualization, Data curation, Writing – review & editing.

**Vanesa Papiol:** Data curation, Writing – review & editing.

**Víctor Eduardo Gómez-Bretón:** Supervision, Data curation, Investigation, Writing – review & editing.

**Damián Alejandro Cedillo-Reyna:** Supervision, Data curation, Investigation, Writing – review & editing.

**Alan Javier Ramírez-Menéndez:** Data curation, Writing – review & editing.

**Miguel Ángel Plata-Díaz:** Supervision, Data curation, Investigation, Writing – review & editing.

**Rodrigo Contreras-Chávez:** Data curation, Writing – review & editing.

**Ximena Isabel Pérez-Meza:** Data curation, Writing – review & editing.

## Funding

This research was supported by the Dirección General de Asuntos del Personal Académico (DGAPA) of the Universidad Nacional Autónoma de México (UNAM) through the Programa de Apoyo a Proyectos de Investigación e Innovación Tecnológica (PAPIIT), under grant number IN208124, awarded to Edlin Guerra-Castro.

## Citation

This repository supports the manuscript **“Scaling spatiotemporal reef-fish monitoring with computer vision in the southern Gulf of Mexico.”**

Source code and version history are maintained at [GitHub](https://github.com/edlinguerra/reef-fish-rfdetr). The versioned reproducibility package and validation-selected model checkpoint are archived in Zenodo at **[10.5281/zenodo.22950727](https://doi.org/10.5281/zenodo.22950727)**.

If you use these materials, please cite the Zenodo release and the associated article.

## License

Original source code and scripts authored for this repository are available under the [PolyForm Noncommercial License 1.0.0](LICENSES/PolyForm-Noncommercial-1.0.0.txt), except where a file explicitly states otherwise. Commercial use is not permitted under this license.

Author-generated derived datasets, tables, manifests, metadata, and other eligible research outputs are available under [CC BY-NC-SA 4.0](LICENSES/CC-BY-NC-SA-4.0.txt), unless otherwise noted and only where the project has the rights to license them. Reuse requires attribution, is limited to non-commercial purposes, and derivative material must use the same license where the CC BY-NC-SA terms apply.

Third-party images, institutional logos, upstream software and model assets, and other materials carrying separate rights statements are not covered by the repository-wide licenses described above. This includes iNaturalist and other externally sourced photographs; SAMP photographs unless explicitly released under a stated license; photographic previews or renders containing restricted imagery; third-party software; upstream RF-DETR source code and pretrained/base weights; and model checkpoints or weights without an accompanying explicit license. Their reuse is governed by the applicable source license, rights statement, or accompanying documentation.

The validation-selected model checkpoint is distributed through the Zenodo release under the applicable model and upstream license terms documented with the archived materials.

Reuse should acknowledge PAPIIT-UNAM project IN208124 and the manuscript authors and project source as appropriate. See [`LICENSES/README.md`](LICENSES/README.md) and [`NOTICE`](NOTICE) for the detailed scope and attribution notice.
