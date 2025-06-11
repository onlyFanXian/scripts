#!/bin/zsh

# 根目录
root_dir="$1"

# 递归查找所有形如 * Set.xx 的目录
find "$root_dir" -type d -name "* Set.*" | while read -r set_folder; do
  parent_dir=$(dirname "$set_folder")
  folder_name=$(basename "$set_folder")

  # 提取目标文件夹名（去掉 " Set.xx" 部分）
  base_name="${folder_name% Set.*}"
  target_dir="$parent_dir/$base_name"

  echo "处理: $folder_name → 合并到: $(basename "$target_dir")"

  mkdir -p "$target_dir"

  # 遍历文件夹内容
  for file in "$set_folder"/*; do
    [[ -f "$file" ]] || continue
    base_file=$(basename "$file")
    dest="$target_dir/$base_file"

    # 避免重名
    if [[ -e "$dest" ]]; then
      count=1
      ext="${base_file##*.}"
      name="${base_file%.*}"
      while [[ -e "$target_dir/${name}_$count.$ext" ]]; do
        ((count++))
      done
      dest="$target_dir/${name}_$count.$ext"
    fi

    mv "$file" "$dest"
  done
done

echo "✅ 所有 Set 文件夹内容已递归合并完毕。"
