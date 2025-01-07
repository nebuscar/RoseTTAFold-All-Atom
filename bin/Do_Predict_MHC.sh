#!/bin/bash

# 目录路径配置
config_dir="rf2aa/config/inference/MHC"
config_files=$(find "$config_dir" -mindepth 1 -type f)

echo "Found the following config files: $config_files"

# 循环处理每个文件
for i_config_file in $config_files; do

    file_name=$(basename "$i_config_file" .yaml)  # 去掉文件后缀 .yaml
    mhc_name=$(echo "$file_name" | sed -E 's/^config_(MHC_[^\.]+)$/\1/')
    
    echo "Found config_file: $file_name"
    echo "Found TCR: $mhc_name"
    
    python -m rf2aa.run_inference --config-name "$file_name"
    echo "Running inference for $mhc_name"
done

