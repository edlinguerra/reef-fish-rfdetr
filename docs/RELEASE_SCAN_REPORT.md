# Release scan report

**Scan date:** 2026-09-24  
**Scope:** complete curated repository before Git initialization

## Checks performed

| Check | Result |
|---|---|
| Workstation absolute paths and usernames | No remaining matches outside the intentionally public provenance-URL manifest. |
| Token, password, API-key, bearer-token, cloud-key, and private-key patterns | No matches. |
| Raw image files | None present. |
| Model checkpoints or weight files | None present. |
| ZIP/archive bundles | None present. |
| Temporary environments, `node_modules`, and generated figure-output directory | None present. |
| Evaluation JSON private paths | No remaining absolute workstation paths. |
| Provenance URLs | 2,772 nonempty source URLs present; no access-token, API-key, signature, localhost, `file://`, or similar risky pattern detected. |
| Geographic coordinates or GPS fields | None identified. References to “coordinates” concern UMAP feature-space coordinates only. |
| Automated scientific integrity test | Passed. |
| Python syntax parsing | Passed. |
| R syntax parsing | Passed for eight R scripts. |

## Issues found and corrected

The saved test-prediction JSON contained 520 absolute workstation paths in an auxiliary image field. The common private prefix and username were removed, leaving only the project image filename. Image identifiers, image dimensions, category records, detection boxes, scores, and annotation counts were unchanged.

An initially copied dataset source-summary table retained an obsolete `UNKNOWN/REVIEW` category. It was replaced with the accepted exhaustive filename-rule accounting: names beginning with `2024` or `2025` are SAMP, and all remaining names are iNaturalist. The final public tables contain only those two source categories.

The retained edited three-epoch training launcher was excluded because it belongs to a separate later output and would misrepresent the final ten-epoch run. The exact recovered configuration is released in YAML instead.

## Authorized external URLs

URLs in `metadata/inaturalist_provenance_manifest.csv` are an intentional public metadata deliverable. They point to original sources and do not include downloaded image content. Some point to external domains other than iNaturalist, as documented in `metadata/EXTERNAL_IMAGE_PROVENANCE.md`. URL presence does not imply verified creator attribution or license.

## Release decision

The repository is suitable for local Git initialization and private remote staging. Public release still requires author confirmation of the code license, final citation metadata, repository URL, DOI placeholders, and any separately deposited checkpoint or SAMP image rights.
