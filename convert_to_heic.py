#!/usr/bin/env python3

import sys
import subprocess
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

def convert_image(image_path: Path):
    if not image_path.exists() or not image_path.is_file():
        return

    if image_path.suffix.lower() not in ['.jpg', '.jpeg', '.png', '.tiff']:
        return

    output_path = image_path.with_suffix('.heic')
    try:
        subprocess.run([
            'sips',
            '--setProperty', 'format', 'heic',
            str(image_path),
            '--out', str(output_path)
        ], check=True)
        image_path.unlink()
        print(f"✅ {image_path.name} → {output_path.name}")
    except subprocess.CalledProcessError as e:
        print(f"❌ 转换失败: {image_path.name}, 错误: {e}")

def main(input_path: Path):
    files = []
    if input_path.is_file():
        files = [input_path]
    elif input_path.is_dir():
        files = [f for f in input_path.rglob("*") if f.suffix.lower() in ['.jpg', '.jpeg', '.png', '.tiff']]
    else:
        print("❌ 路径无效")
        return

    with ThreadPoolExecutor(max_workers=8) as executor:
        executor.map(convert_image, files)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("用法: python fast_sips.py <文件或文件夹路径>")
        sys.exit(1)

    main(Path(sys.argv[1]).expanduser().resolve())
