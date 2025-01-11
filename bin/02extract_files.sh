#!/bin/bash

# 定义数据库目录（读取源文件的路径）
DATABASE_DIR="database"

# 定义目标目录
TARGET_DIR="$HOME/data"

# 创建目标目录（如果不存在的话）
mkdir -p "$TARGET_DIR"

# 定义文件列表以及相应的解压目标子目录
FILES=(
    "UniRef30_2020_06_hhsuite.tar.gz:$TARGET_DIR/UniRef30_2020_06"
    "bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt.tar.gz:$TARGET_DIR/bfd"
    "pdb100_2021Mar03.tar.gz:$TARGET_DIR"
)

# 使用 pigz 解压文件并指定目标目录
for file_info in "${FILES[@]}"; do
    # 从文件信息中提取文件名和目标目录
    IFS=":" read -r file destination <<< "$file_info"

    # 构建完整的文件路径（从 DATABASE_DIR 中读取文件）
    full_file_path="$DATABASE_DIR/$file"

    # 检查文件是否存在
    if [[ ! -f "$full_file_path" ]]; then
        echo "Error: File '$full_file_path' does not exist in database directory."
        continue  # 跳过当前文件，继续处理下一个文件
    fi

    # 创建目标子目录（如果不存在的话）
    mkdir -p "$destination"

    echo "Extracting $full_file_path to $destination..."

    # 解压文件并行执行
    tar --use-compress-program=pigz -xvf "$full_file_path" -C "$destination" & 
done

# 等待所有解压进程完成
wait

echo "All files have been extracted."

