#!/usr/bin/env python3
"""Batch archive inference used by the v17 deployment workflow.

This public version replaces workstation-specific paths with required command-line
arguments. It preserves RF-DETR Medium, checkpoint loading, the 0.50 default
threshold, category mapping, six-directory traversal, and resumable COCO-like
output behavior of the retained deployment script.
"""
from __future__ import annotations

import argparse
import json
import warnings
from pathlib import Path

import numpy as np
from PIL import Image
from rfdetr import RFDETRMedium


TARGET_DIRECTORIES = [f"p{i:05d}" for i in range(1, 7)]
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", type=Path, required=True,
                        help="Locally obtained checkpoint_best_total.pth.")
    parser.add_argument("--archive-root", type=Path, required=True,
                        help="Directory containing p00001 through p00006.")
    parser.add_argument("--class-map-coco", type=Path, required=True,
                        help="COCO file supplying the accepted category map.")
    parser.add_argument("--output-json", type=Path, required=True)
    parser.add_argument("--progress-json", type=Path, required=True)
    parser.add_argument("--threshold", type=float, default=0.50)
    parser.add_argument("--save-every", type=int, default=1000)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    warnings.filterwarnings("ignore", category=UserWarning, message="torch.meshgrid")
    with args.class_map_coco.open("r", encoding="utf-8") as handle:
        coco_base = json.load(handle)
    categories = coco_base["categories"]
    if args.progress_json.exists():
        with args.progress_json.open("r", encoding="utf-8") as handle:
            output = json.load(handle)
    else:
        output = {"info": coco_base.get("info", {}),
                  "licenses": coco_base.get("licenses", []),
                  "categories": categories, "images": [], "annotations": []}
    processed = {item["file_name"] for item in output["images"]}
    image_id = max((item["id"] for item in output["images"]), default=-1) + 1
    annotation_id = max((item["id"] for item in output["annotations"]), default=-1) + 1
    model = RFDETRMedium(pretrain_weights=str(args.checkpoint))
    images: list[Path] = []
    for directory in TARGET_DIRECTORIES:
        location = args.archive_root / directory
        if not location.exists():
            raise FileNotFoundError(f"Missing archive directory: {location}")
        images.extend(path for path in location.rglob("*")
                      if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS)
    images.sort()
    pending = [path for path in images if path.name not in processed]
    for index, image_path in enumerate(pending, start=1):
        try:
            with Image.open(image_path) as image:
                image.verify()
            with Image.open(image_path) as image:
                width, height = image.convert("RGB").size
            current_id = image_id
            image_id += 1
            output["images"].append({
                "id": current_id, "file_name": image_path.name,
                "height": height, "width": width,
                "extra": {"rel_path": str(image_path.relative_to(args.archive_root))},
            })
            detections = model.predict(str(image_path), threshold=args.threshold)
            class_ids = detections.class_id.astype(int)
            category_ids = (np.clip(class_ids - 1, 0, None) + 1).astype(int)
            boxes = detections.xyxy.astype(float)
            for detection_index in range(len(detections)):
                x1, y1, x2, y2 = boxes[detection_index]
                box_width, box_height = max(0.0, x2-x1), max(0.0, y2-y1)
                output["annotations"].append({
                    "id": annotation_id, "image_id": current_id,
                    "category_id": int(category_ids[detection_index]),
                    "bbox": [float(x1), float(y1), float(box_width), float(box_height)],
                    "area": float(box_width * box_height), "iscrowd": 0,
                    "score": float(detections.confidence[detection_index]),
                })
                annotation_id += 1
        except Exception as error:  # preserve skip-on-unreadable-image behavior
            print(f"Skipping {image_path.name}: {error}")
            continue
        if index % args.save_every == 0:
            args.progress_json.parent.mkdir(parents=True, exist_ok=True)
            args.progress_json.write_text(json.dumps(output), encoding="utf-8")
    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    args.output_json.write_text(json.dumps(output, indent=2), encoding="utf-8")
    if args.progress_json.exists():
        args.progress_json.unlink()
    print(f"Processed archive records: {len(output['images'])}")


if __name__ == "__main__":
    main()
