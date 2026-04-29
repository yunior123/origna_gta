from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path

import fitz
from PIL import Image, ImageStat

SCREENSHOT_RE = re.compile(
    r"^\d{3}-live-(gta|ventures)-.+-desktop-(1280|1440|1600|1728)-y\d{5}\.png$"
)
PDF_NAME_RE = re.compile(r"\d{3}-live-[^\s]+?\.png")
BAD_NAME_RE = re.compile(
    r"artifact|extracted|mascot|product-placeholder|design-token|checkout|pricing-fr|pricing-es",
    re.IGNORECASE,
)


def validate_screenshots(path: Path, expected_count: int) -> None:
    files = sorted(path.glob("*.png"))
    issues: list[str] = []
    hashes: dict[str, str] = {}
    for index, file in enumerate(files, start=1):
        match = SCREENSHOT_RE.fullmatch(file.name)
        if not match:
            issues.append(f"bad screenshot name: {file.name}")
            continue
        image_hash = hashlib.sha256(file.read_bytes()).hexdigest()
        if image_hash in hashes:
            issues.append(f"duplicate screenshot: {file.name} matches {hashes[image_hash]}")
        else:
            hashes[image_hash] = file.name
        if int(file.name[:3]) != index:
            issues.append(f"bad screenshot sequence: {file.name}")
        image = Image.open(file).convert("RGB")
        expected_size = (int(match.group(2)), 900)
        if image.size != expected_size:
            issues.append(f"bad screenshot size: {file.name} {image.size} != {expected_size}")
        stat = ImageStat.Stat(image.resize((96, 54)))
        if file.stat().st_size <= 25_000:
            issues.append(f"screenshot too small: {file.name} {file.stat().st_size}")
        if sum(stat.var) / 3 < 15:
            issues.append(f"screenshot appears blank: {file.name}")
    if len(files) != expected_count:
        issues.append(f"expected {expected_count} screenshots, found {len(files)}")
    if issues:
        raise SystemExit("\n".join(issues))


def validate_pdf(path: Path, expected_count: int, expected_pages: int) -> None:
    doc = fitz.open(path)
    text = "\n".join(page.get_text() for page in doc)
    names = PDF_NAME_RE.findall(text)
    bad_names = [name for name in names if BAD_NAME_RE.search(name)]
    render_issues: list[int] = []
    for page in doc:
        pix = page.get_pixmap(matrix=fitz.Matrix(0.2, 0.2), alpha=False)
        image = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        if sum(ImageStat.Stat(image.resize((64, 45))).var) / 3 < 20:
            render_issues.append(page.number + 1)
    issues: list[str] = []
    if doc.page_count != expected_pages:
        issues.append(f"{path}: expected {expected_pages} pages, found {doc.page_count}")
    if len(names) != expected_count:
        issues.append(f"{path}: expected {expected_count} screenshot names, found {len(names)}")
    if bad_names:
        issues.append(f"{path}: bad screenshot names: {bad_names[:10]}")
    if "Unable to render screenshot" in text:
        issues.append(f"{path}: contains screenshot placeholder text")
    if render_issues:
        issues.append(f"{path}: blank rendered pages: {render_issues}")
    if issues:
        raise SystemExit("\n".join(issues))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--screenshots", type=Path, required=True)
    parser.add_argument("--deck", type=Path, action="append", default=[])
    parser.add_argument("--expected-count", type=int, default=64)
    parser.add_argument("--expected-pages", type=int, default=63)
    args = parser.parse_args()

    validate_screenshots(args.screenshots, args.expected_count)
    for deck in args.deck:
        validate_pdf(deck, args.expected_count, args.expected_pages)
    print(
        f"validated {args.expected_count} screenshots and {len(args.deck)} deck PDF(s)"
    )


if __name__ == "__main__":
    main()
