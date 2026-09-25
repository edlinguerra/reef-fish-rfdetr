# Training workflow status

The exact launcher that initiated the authoritative ten-epoch v17 run was not retained as a standalone script. The surviving edited `train_rfdetr_peces_Bajo_10.py` points to a separate `output_1` directory and three epochs, so it is intentionally excluded rather than misrepresented as the final-run launcher.

The verified expanded run configuration is transcribed in `config/training.yaml` and `config/final_model.yaml`. Those files support accurate description and reconstruction of the recorded settings, but do not guarantee byte-identical retraining because the exact RF-DETR package build, optimizer class, original split-allocation procedure, and complete random-state controls were not recovered.
