# Tests

Run `python tests/test_public_package.py` from the repository root. The checks use only the Python standard library and do not rerun model inference, COCO evaluation, UMAP, or permutation analyses.

They verify the retained numerical inputs for Figures 2–6 and Table 1, the selected validation epoch, corrected diagnostic denominators, leakage-sensitivity bound, ontology size, archive-scale counts, provenance coverage, and exclusion of image/model/archive binaries.
