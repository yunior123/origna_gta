from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path
from typing import Iterable, List

from PIL import Image, ImageDraw

IMAGE_EXTENSIONS = {'.png', '.jpg', '.jpeg', '.webp'}
SCREEN_SUFFIXES = ('_desktop', '_mobile', '_tablet', '_web')
COMPONENT_KEYWORDS = {
    'button',
    'card',
    'badge',
    'banner',
    'palette',
    'gradient',
    'loading',
    'field',
    'variants',
    'states',
    'timeline',
    'responsive',
    'legal',
    'promo',
    'rating',
    'histogram',
    'animations',
    'empty_',
    'typography',
    'app_bar',
    'bottom_nav',
    'status_',
    'order_summary',
    'language_',
    'canadian_moose',
    'color_',
    'env_',
}


def collect_images(paths: Iterable[Path]) -> List[Path]:
    files: List[Path] = []
    for path in paths:
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS:
            files.append(path)
            continue
        if path.is_dir():
            files.extend(sorted(p for p in path.rglob('*') if p.suffix.lower() in IMAGE_EXTENSIONS))
    deduped: List[Path] = []
    seen: set[str] = set()
    for file in files:
        key = str(file.resolve())
        if key in seen:
            continue
        seen.add(key)
        deduped.append(file)
    return deduped


def classify_image(path: Path) -> str:
    stem = path.stem.lower()
    if 'contact_sheet' in stem:
        return 'contact_sheets'
    if stem.endswith(SCREEN_SUFFIXES):
        return 'full_screens'
    if any(keyword in stem for keyword in COMPONENT_KEYWORDS):
        return 'components'
    return 'full_screens'


def verify_image(path: Path) -> dict:
    try:
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            width, height = image.size
        return {
            'path': str(path),
            'ok': True,
            'width': width,
            'height': height,
            'category': classify_image(path),
        }
    except Exception as error:  # pragma: no cover - utility script
        return {
            'path': str(path),
            'ok': False,
            'error': str(error),
            'category': classify_image(path),
        }


def copy_group(images: List[Path], dest: Path, start_index: int) -> tuple[list[Path], int]:
    copied: List[Path] = []
    index = start_index
    for source in images:
        target = dest / f'{index:04d}_{source.name}'
        shutil.copy2(source, target)
        copied.append(target)
        index += 1
    return copied, index


def generate_contact_sheet(source_images: List[Path], output_path: Path, title: str) -> None:
    cell_w = 540
    cell_h = 360
    margin = 36
    cols = 2
    rows = 3
    sheet_w = margin * 2 + cols * cell_w
    sheet_h = margin * 2 + rows * cell_h + 40

    canvas = Image.new('RGB', (sheet_w, sheet_h), '#faf6f6')
    draw = ImageDraw.Draw(canvas)
    draw.text((margin, 12), title, fill='#8B0000')

    for idx, image_path in enumerate(source_images[: cols * rows]):
        x = margin + (idx % cols) * cell_w
        y = 40 + margin + (idx // cols) * cell_h
        try:
            image = Image.open(image_path).convert('RGB')
            image.thumbnail((cell_w - 16, cell_h - 30))
            paste_x = x + (cell_w - image.width) // 2
            paste_y = y + 8 + (cell_h - 30 - image.height) // 2
            canvas.paste(image, (paste_x, paste_y))
            draw.rectangle((x, y, x + cell_w - 1, y + cell_h - 1), outline='#d8b2b2', width=2)
            draw.text((x + 10, y + cell_h - 18), image_path.stem[:52], fill='#1A1A1A')
        except Exception:
            draw.rectangle((x, y, x + cell_w - 1, y + cell_h - 1), outline='#d8b2b2', width=2)
            draw.text((x + 10, y + 10), image_path.name[:50], fill='#1A1A1A')

    canvas.save(output_path)


def export_bundle(images: List[Path], dest: Path) -> dict:
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True, exist_ok=True)

    verified = [verify_image(path) for path in images]
    good = [Path(item['path']) for item in verified if item['ok']]

    grouped = {
        'full_screens': [],
        'components': [],
        'contact_sheets': [],
    }
    for path in good:
        grouped[classify_image(path)].append(path)

    copied: dict[str, list[Path]] = {}
    next_index = 1
    for group_name in ('full_screens', 'components'):
        target_dir = dest / group_name
        target_dir.mkdir(parents=True, exist_ok=True)
        copied[group_name], next_index = copy_group(grouped[group_name], target_dir, next_index)

    contact_dir = dest / 'contact_sheets'
    contact_dir.mkdir(parents=True, exist_ok=True)
    generated_contacts: list[Path] = []
    contact_sources = copied['full_screens'] if copied['full_screens'] else copied['components']
    for sheet_index in range(0, len(contact_sources), 6):
        subset = contact_sources[sheet_index:sheet_index + 6]
        if not subset:
            continue
        output_path = contact_dir / f'{next_index:04d}_contact_sheet_{sheet_index // 6 + 1:03d}.png'
        generate_contact_sheet(subset, output_path, f'OrignaGTA Contact Sheet {sheet_index // 6 + 1}')
        generated_contacts.append(output_path)
        next_index += 1
    copied['contact_sheets'] = generated_contacts

    manifest = {
        'verified_total': len(verified),
        'verified_ok': sum(1 for item in verified if item['ok']),
        'verified_failed': [item for item in verified if not item['ok']],
        'counts': {key: len(value) for key, value in copied.items()},
        'files': {key: [path.name for path in value] for key, value in copied.items()},
    }
    (dest / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    (dest / 'README.txt').write_text(
        '\n'.join(
            [
                'Origna Ventures app image export',
                f"full_screens: {len(copied['full_screens'])}",
                f"components: {len(copied['components'])}",
                f"contact_sheets: {len(copied['contact_sheets'])}",
                f"verified_ok: {manifest['verified_ok']}",
                f"verified_failed: {len(manifest['verified_failed'])}",
            ]
        ) + '\n',
        encoding='utf-8',
    )
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--dest', type=Path, required=True)
    parser.add_argument('sources', nargs='+', type=Path)
    args = parser.parse_args()

    images = collect_images(args.sources)
    manifest = export_bundle(images, args.dest)
    print(json.dumps(manifest['counts'], indent=2))
    print(f"verified_ok={manifest['verified_ok']} verified_failed={len(manifest['verified_failed'])}")
