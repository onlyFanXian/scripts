#!/usr/bin/env python3
import os
import sys
import subprocess

def set_title(filepath, title):
    try:
        subprocess.run([
            "exiftool",
            f"-Title={title}",
            f"-ObjectName={title}",
            "-overwrite_original",
            filepath
        ], check=True)
        print(f"✅ 设置标题: {filepath} → {title}")
    except subprocess.CalledProcessError as e:
        print(f"❌ 设置失败: {filepath} → {e}")

def process_folder(folder):
    for root, _, files in os.walk(folder):
        for file in files:
            if file.lower().endswith(('.heic', '.jpg', '.jpeg')):
                filepath = os.path.join(root, file)
                title = os.path.splitext(file)[0]
                set_title(filepath, title)

def main():
    if len(sys.argv) != 2:
        print("用法: python set_title_recursive.py <顶级文件夹路径>")
        return

    folder = sys.argv[1]
    if not os.path.isdir(folder):
        print("❌ 路径无效")
        return

    process_folder(folder)

if __name__ == "__main__":
    main()
