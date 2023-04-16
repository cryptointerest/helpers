#!/bin/bash

input_folder=$1
desired_sample_rate=${2:-48000}
desired_bit_depth=${3:-24}

for file in $input_folder/*.flac; do 
	file_name="$(basename -- "$file")"
	output_dirname=${file%/*}
	output_dirname=${output_dirname/"24_96"/"${desired_bit_depth}_${desired_sample_rate}"}
	if [ ! -d "$output_dirname" ]; then
		mkdir $output_dirname
	fi
	ReSampler -i $file -o $output_dirname/$file_name -r $desired_sample_rate -b $desired_bit_depth --relaxedLPF --lpf-cutoff 89  -mt --flacCompression 6 --doubleprecision
done
