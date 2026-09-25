# Environment recovery status

`python-environment.yml` records the verified Python 3.11.14, PyTorch 2.9.1+cu128/CUDA 12.8 context and Roboflow 1.2.11, while leaving unrecovered package versions unpinned. `requirements-unpinned.txt` is therefore a dependency list, not a lock file.

`r-package-versions.txt` records versions retained for the analysis packages. The exact R interpreter version used for the accepted analyses was not retained. A new lock file was not generated because it would describe the present workstation rather than the historical final-run environment.
