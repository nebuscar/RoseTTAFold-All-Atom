#!/bin/bash

# 目录路径配置
input_dir="inputs/TCR"
output_dir="outputs/TCR"
checkpoint="RFAA_paper_weights.pt"
hhdb_path="pdb100_2021Mar03/pdb100_2021Mar03"
num_cpus=6
mem=64
config_dir="$HOME/Projects/RoseTTAFold-All-Atom/rf2aa/config/inference/TCR" 

# 循环处理
folders=$(find "$input_dir" -mindepth 1 -type d)
echo "Found the following folders:"
echo "$folders"

for folder in $folders; do
    # 获取当前文件夹名称，作为job_name的一部分
    job_name="TCR_protein_${folder##*/}"
    output_path="${output_dir}/TCR_protein_${folder##*/}"
    mkdir -p "$output_path"
    echo "Processing job: $job_name"
    echo "Output path: $output_path"
    
    # 设置每个蛋白的FASTA文件路径
    fasta_files=$(find "$folder" -type f -name "rcsb_pdb_*_*.fasta")
    echo "fasta processing: $fasta_files"

    # 生成配置文件，文件名以folder名称为前缀，保存到指定路径
    config_file="${config_dir}/config_TCR_${folder##*/}.yaml"  # 保存到指定路径
    cat > "$config_file" <<EOL
defaults:
  - base

job_name: "$job_name"

output_path: "$output_path"
checkpoint_path: "$checkpoint"
database_params:
  sequencedb: ""
  hhdb: "$hhdb_path"
  command: make_msa.sh
  num_cpus: $num_cpus
  mem: $mem

protein_inputs:
EOL

    for fasta in $fasta_files; do
        chain=$(basename "$fasta" | sed -E 's/.*_(.)\.fasta/\1/')
        echo "Found $fasta, adding chain $chain to config..."
        echo "  $chain:" >> "$config_file"
        echo "    fasta_file: \"$fasta\"" >> "$config_file"
    done

    echo "Configuration file generated: $config_file"
    
    echo "Running inference for $job_name"
    
done

