#!/bin/bash

# 定义源目录和目标目录
SOURCE_DIR="$HOME/data"
TARGET_DIR="$HOME/Projects/RoseTTAFold-All-Atom"

# 定义文件及其对应目标子目录
FILES=(
    "UniRef30_2020_06_hhsuite:UniRef30_2020_06"
    "bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt.tar:bfd"
    "pdb100_2021Mar03:"
)

# 创建软连接
for file_info in "${FILES[@]}"; do
    # 从文件信息中提取文件名和目标子目录
    IFS=":" read -r file subdir <<< "$file_info"

    # 目标路径
    TARGET_PATH="$TARGET_DIR/$subdir"

    # 如果子目录存在，则直接创建软连接，否则先创建子目录
    if [ -n "$subdir" ]; then
        mkdir -p "$TARGET_PATH"
    fi

    # 创建软连接
    ln -s "$SOURCE_DIR/$file" "$TARGET_PATH/$file"
    echo "Created symbolic link for $file -> $TARGET_PATH/$file"
done

