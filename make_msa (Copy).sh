#!/bin/bash

# 输入参数params
in_fasta="$1"
out_dir="$2"

# 资源配置
CPU="$3"
MEM="$4"

# template database
DB_TEMPL="$5"

# current script directory (i.e., pipe directory)
SCRIPT=`realpath -s $0` # 脚本所在绝对路径
export PIPE_DIR=`dirname $SCRIPT` # 将脚本绝对路径设置添加到环境变量

# sequence databases

## 1. UniRef30数据库路径
# DB_UR30="$PIPE_DIR/UniRef30_2020_06/UniRef30_2020_06"
DB_UR30="/home/wangshiyu/data/UniRef30_2020_06/UniRef30_2020_06"

## 2. BFD数据库路径
# DB_BFD="$PIPE_DIR/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt"
DB_BFD="/home/wangshiyu/data/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt"

# Running signalP 6.0
mkdir -p $out_dir/signalp # 创建signalp6输出路径
tmp_dir="$out_dir/signalp"

## signalp6分析输入的FASTA文件
signalp6 --fastafile $in_fasta --organism other --output_dir
$tmp_dir --format none --mode slow
trim_fasta="$tmp_dir/processed_entries.fasta"

## 若处理后的文件不存在或为空，使用原始FASTA文件
if [ ! -s $trim_fasta ] # empty file -- no signal P
then
    trim_fasta="$in_fasta"
fi


# setup hhblits command

# export HHLIB=/software/hhsuite/build/bin/
export HHLIB=/home/wangshiyu/software/anaconda3/envs/RFAA/bin/
export PATH=$HHLIB:$PATH
HHBLITS_UR30="hhblits -o /dev/null -mact 0.35 -maxfilt 100000000 -neffmax 20 -cov 25 -cpu $CPU -nodiff -realign_max 100000000 -maxseq 1000000 -maxmem $MEM -n 4 -d $DB_UR30"
HHBLITS_BFD="hhblits -o /dev/null -mact 0.35 -maxfilt 100000000 -neffmax 20 -cov 25 -cpu $CPU -nodiff -realign_max 100000000 -maxseq 1000000 -maxmem $MEM -n 4 -d $DB_BFD"

mkdir -p $out_dir/hhblits
tmp_dir="$out_dir/hhblits"
out_prefix="$out_dir/t000_"

# perform iterative searches against UniRef30
# 运行Hhblits对UniRef30数据库进行多轮迭代搜索

## 检查初始对齐文件是否存在，若不存在，则执行多轮Hhblits搜索
if [ ! -s ${out_prefix}.msa0.a3m ]
then
    prev_a3m="$trim_fasta" # 以处理后的FASTA文件作为初始输入
    for e in 1e-10 1e-6 1e-3 # 使用不同的E-value循环迭代
    do
        echo "Running HHblits against UniRef30 with E-value cutoff $e"
        if [ ! -s $tmp_dir/t000_.$e.a3m ]
        then
            $HHBLITS_UR30 -i $prev_a3m -oa3m $tmp_dir/t000_.$e.a3m -e $e -v 0
        fi
        
        ## 过滤序列：ID 90%，覆盖率 75% 和 50%
        hhfilter -maxseq 100000 -id 90 -cov 75 -i $tmp_dir/t000_.$e.a3m -o $tmp_dir/t000_.$e.id90cov75.a3m
        hhfilter -maxseq 100000 -id 90 -cov 50 -i $tmp_dir/t000_.$e.a3m -o $tmp_dir/t000_.$e.id90cov50.a3m
        prev_a3m="$tmp_dir/t000_.$e.id90cov50.a3m"
        
        ## 检查过滤后的序列数量，满足条件则保存
        n75=`grep -c "^>" $tmp_dir/t000_.$e.id90cov75.a3m`
        n50=`grep -c "^>" $tmp_dir/t000_.$e.id90cov50.a3m`

        if ((n75>2000))
        then
            if [ ! -s ${out_prefix}.msa0.a3m ]
            then
                cp $tmp_dir/t000_.$e.id90cov75.a3m ${out_prefix}.msa0.a3m
                break
            fi
        elif ((n50>4000))
        then
            if [ ! -s ${out_prefix}.msa0.a3m ]
            then
                cp $tmp_dir/t000_.$e.id90cov50.a3m ${out_prefix}.msa0.a3m
                break
            fi
        else
            continue
        fi
    done

    # perform iterative searches against BFD if it failes to get enough sequences
    # 若没有获取到足够的序列，则对BFD数据库进行补充搜索
    if [ ! -s ${out_prefix}.msa0.a3m ] 
    then
        e=1e-3
        echo "Running HHblits against BFD with E-value cutoff $e"
        if [ ! -s $tmp_dir/t000_.$e.bfd.a3m ]
        then
            $HHBLITS_BFD -i $prev_a3m -oa3m $tmp_dir/t000_.$e.bfd.a3m -e $e -v 0
        fi
        
        ## 重复过滤和判断条件
        hhfilter -maxseq 100000 -id 90 -cov 75 -i $tmp_dir/t000_.$e.bfd.a3m -o $tmp_dir/t000_.$e.bfd.id90cov75.a3m
        hhfilter -maxseq 100000 -id 90 -cov 50 -i $tmp_dir/t000_.$e.bfd.a3m -o $tmp_dir/t000_.$e.bfd.id90cov50.a3m
        prev_a3m="$tmp_dir/t000_.$e.bfd.id90cov50.a3m"
        n75=`grep -c "^>" $tmp_dir/t000_.$e.bfd.id90cov75.a3m`
        n50=`grep -c "^>" $tmp_dir/t000_.$e.bfd.id90cov50.a3m`

        if ((n75>2000))
        then
            if [ ! -s ${out_prefix}.msa0.a3m ]
            then
                cp $tmp_dir/t000_.$e.bfd.id90cov75.a3m ${out_prefix}.msa0.a3m
            fi
        elif ((n50>4000))
        then
            if [ ! -s ${out_prefix}.msa0.a3m ]
            then
                cp $tmp_dir/t000_.$e.bfd.id90cov50.a3m ${out_prefix}.msa0.a3m
            fi
        fi
    fi

    if [ ! -s ${out_prefix}.msa0.a3m ]
    then
        cp $prev_a3m ${out_prefix}.msa0.a3m
    fi
fi


# 运行 PSIPRED预测次级结构
echo "Running PSIPRED"
mkdir -p $out_dir/log
$PIPE_DIR/input_prep/make_ss.sh $out_dir/t000_.msa0.a3m $out_dir/t000_.ss2 > $out_dir/log/make_ss.stdout 2> $out_dir/log/make_ss.stderr


# 运行HHsearch比对数据库模板
if [ ! -s $out_dir/t000_.hhr ]
then
    echo "Running hhsearch"
    HH="hhsearch -b 50 -B 500 -z 50 -Z 500 -mact 0.05 -cpu $CPU -maxmem $MEM -aliw 100000 -e 100 -p 5.0 -d $DB_TEMPL"
    
    cat $out_dir/t000_.ss2 $out_dir/t000_.msa0.a3m > $out_dir/t000_.msa0.ss2.a3m
    $HH -i $out_dir/t000_.msa0.ss2.a3m -o $out_dir/t000_.hhr -atab $out_dir/t000_.atab -v 0
fi
