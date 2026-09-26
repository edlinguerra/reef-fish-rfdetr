# Software environment

`python-environment.yml` documents Python 3.11.14, PyTorch 2.9.1+cu128, CUDA 12.8, and Roboflow 1.2.11. Packages without a recorded version remain unpinned, so `requirements-unpinned.txt` is a dependency list rather than a lock file.

`r-package-versions.txt` lists the available package versions associated with the corrected analyses and figure workflows. The R interpreter version is not documented. No `renv.lock` is supplied, and the repository does not claim byte-identical recreation of the original R environment.
