#!/bin/bash

# 目录路径配置
config_dir="rf2aa/config/inference/TCR_todo"
config_files=$(find "$config_dir" -mindepth 1 -type f)

echo "Found the following config files: $config_files"

# 循环处理每个文件
for i_config_file in $config_files; do
    # 提取文件名（例如：config_TCR_7ZT7.yaml）并从中提取TCR_7ZT7部分
    file_name=$(basename "$i_config_file" .yaml)  # 去掉文件后缀 .yaml
    tcr_name=$(echo "$file_name" | sed -E 's/^config_(TCR_[^\.]+)$/\1/')  # 提取 TCR_部分
    
    echo "Found config_file: $file_name"
    echo "Found TCR: $tcr_name"
    
    python -m rf2aa.run_inference --config-name "$file_name"
    echo "Running inference for $tcr_name"
done

