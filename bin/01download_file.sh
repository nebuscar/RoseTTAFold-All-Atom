#!/bin/bash

# 设置最大重试次数
MAX_TRIES=5

# 文件下载链接和输出文件名
URLS=(
    "http://wwwuser.gwdg.de/~compbiol/uniclust/2020_06/UniRef30_2020_06_hhsuite.tar.gz"
    "https://bfd.mmseqs.com/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt.tar.gz"
    "https://files.ipd.uw.edu/pub/RoseTTAFold/pdb100_2021Mar03.tar.gz"
)

FILES=(
    "UniRef30_2020_06_hhsuite.tar.gz"
    "bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt.tar.gz"
    "pdb100_2021Mar03.tar.gz"
)

# 下载函数
download_file() {
    local url=$1
    local output_file="database/$2"
    echo "Downloading $FILES to $output_file"

    # 使用 aria2c 下载文件
    aria2c -c -x 16 -s 16 "$url" -o "$output_file"

    if [[ $? -ne 0 ]]; then
        echo "Error downloading $output_file. Retrying..."
        # 重试下载，最多 MAX_TRIES 次
        for (( i=1; i<=$MAX_TRIES; i++ )); do
            echo "Retry attempt $i..."
            aria2c -c -x 16 -s 16 "$url" -o "$output_file"
            if [[ $? -eq 0 ]]; then
                break
            elif [[ $i -eq $MAX_TRIES ]]; then
                echo "Failed to download $output_file after $MAX_TRIES attempts."
                exit 1
            fi
        done
    fi
}

# 下载文件
for i in ${!URLS[@]}; do
    download_file "${URLS[$i]}" "${FILES[$i]}"
    echo "Downloading $FILES to $output_file"
done

echo "All datasets have been successfully downloaded!"

