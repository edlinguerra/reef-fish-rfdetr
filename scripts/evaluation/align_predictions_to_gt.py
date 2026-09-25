#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Alinea un archivo COCO de predicciones contra el COCO ground truth.

Convierte:

{
  "images": [...],
  "annotations": [...],
  "categories": [...]
}

a formato COCO results:

[
  {
    "image_id": ...,
    "category_id": ...,
    "bbox": [x, y, width, height],
    "score": ...
  }
]

La alineación se hace por:
  - file_name para recuperar el image_id correcto
  - category name para recuperar el category_id correcto
"""

import argparse
import json
from pathlib import Path


def basename(x):
    return Path(str(x)).name


def get_score(ann):
    for key in ["score", "confidence", "conf", "probability"]:
        if key in ann:
            return float(ann[key])
    return 1.0


def main():
    parser = argparse.ArgumentParser(
        description="Alinear predicciones COCO contra ground truth COCO."
    )

    parser.add_argument(
        "--gt-json",
        required=True,
        type=Path,
        help="Archivo _annotations.coco.json del ground truth."
    )

    parser.add_argument(
        "--pred-coco",
        required=True,
        type=Path,
        help="Archivo COCO completo con predicciones."
    )

    parser.add_argument(
        "--out-json",
        required=True,
        type=Path,
        help="Archivo de salida en formato COCO results."
    )

    args = parser.parse_args()

    with open(args.gt_json, "r", encoding="utf-8") as f:
        gt = json.load(f)

    with open(args.pred_coco, "r", encoding="utf-8") as f:
        pred = json.load(f)

    if not isinstance(pred, dict):
        raise ValueError("El archivo de predicciones debe ser un COCO completo tipo dict.")

    if "images" not in pred or "annotations" not in pred or "categories" not in pred:
        raise ValueError(
            "El archivo de predicciones debe contener images, annotations y categories."
        )

    gt_images_by_name = {}
    duplicated_gt_names = set()

    for img in gt["images"]:
        name = basename(img["file_name"])
        if name in gt_images_by_name:
            duplicated_gt_names.add(name)
        gt_images_by_name[name] = img["id"]

    if duplicated_gt_names:
        print("Advertencia: hay nombres de imagen duplicados en GT.")
        print("Ejemplos:", list(duplicated_gt_names)[:10])

    pred_image_id_to_name = {
        img["id"]: basename(img["file_name"])
        for img in pred["images"]
    }

    gt_cat_name_to_id = {
        cat["name"]: cat["id"]
        for cat in gt["categories"]
    }

    pred_cat_id_to_name = {
        cat["id"]: cat["name"]
        for cat in pred["categories"]
    }

    results = []

    skipped_no_image = 0
    skipped_no_category = 0
    skipped_bad_bbox = 0

    for ann in pred["annotations"]:
        pred_image_id = ann["image_id"]

        if pred_image_id not in pred_image_id_to_name:
            skipped_no_image += 1
            continue

        file_name = pred_image_id_to_name[pred_image_id]

        if file_name not in gt_images_by_name:
            skipped_no_image += 1
            continue

        gt_image_id = gt_images_by_name[file_name]

        pred_category_id = ann["category_id"]

        if pred_category_id not in pred_cat_id_to_name:
            skipped_no_category += 1
            continue

        category_name = pred_cat_id_to_name[pred_category_id]

        if category_name not in gt_cat_name_to_id:
            skipped_no_category += 1
            continue

        gt_category_id = gt_cat_name_to_id[category_name]

        bbox = ann["bbox"]

        if len(bbox) != 4:
            skipped_bad_bbox += 1
            continue

        x, y, w, h = [float(v) for v in bbox]

        if w <= 0 or h <= 0:
            skipped_bad_bbox += 1
            continue

        results.append(
            {
                "image_id": int(gt_image_id),
                "category_id": int(gt_category_id),
                "bbox": [x, y, w, h],
                "score": get_score(ann),
            }
        )

    args.out_json.parent.mkdir(parents=True, exist_ok=True)

    with open(args.out_json, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print("Alineación terminada.")
    print(f"Predicciones exportadas: {len(results)}")
    print(f"Sin imagen correspondiente: {skipped_no_image}")
    print(f"Sin categoría correspondiente: {skipped_no_category}")
    print(f"BBox inválidas: {skipped_bad_bbox}")
    print(f"Archivo guardado en: {args.out_json}")

    if results:
        print("\nPrimera predicción alineada:")
        print(results[0])


if __name__ == "__main__":
    main()
