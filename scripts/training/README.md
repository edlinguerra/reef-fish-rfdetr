# Training configuration

The final RF-DETR Medium model was trained for ten epochs. Its architecture, optimization settings, model-selection criterion, and hardware context are documented in [`../../config/training.yaml`](../../config/training.yaml) and [`../../config/final_model_config.yaml`](../../config/final_model_config.yaml).

This repository does not include a standalone final-run launcher and does not claim byte-identical retraining. The exact RF-DETR package build, optimizer class, original split-allocation procedure, and complete random-state context are not documented. The published configuration supports transparent description of the training setup and interpretation of the supplied checkpoint and evaluation products.
