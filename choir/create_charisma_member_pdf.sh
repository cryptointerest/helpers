#!/bin/bash

# "shopt -s nullglob" so that an empty directory won't give you a literal '*'. 
shopt -s nullglob

function delete_old_pdf() {
    file_name=$1
    file_and_control_file=$(echo ${file_name%.*}*.pdf)
    for file in $file_and_control_file; do
        if [ -f "$file" ]; then
            rm $file
        fi
    done
}

function create_dir_if_nonexistent(){
    dir_name=$1
    if [ ! -d "$dir_name" ]; then
	mkdir -p $dir_name
    fi
}

function create_downsized_images_in_parallel(){
    num_processes=3
    out_dir=$1
    for jpg_image in *.JPG; do
        ((i=i%num_processes)); ((i++==0)) && wait
	echo "Downscaling image $jpg_image and converting to pdf ..."
	convert_image_to_down_scaled_pdf $jpg_image $out_dir &
    done
    wait
}

function convert_image_to_down_scaled_pdf(){
    file=$1
    out_dir=$2
    fname=`basename $file`
    thumbname="$out_dir/thumb_${fname%.JPG}.pdf"
    echo "generating    ${thumbname}"
    convert -thumbnail x400 ${file} -auto-orient ${thumbname}
}

function concatenate_pdfs() {
    pdf_dir=$1
    out_name=${2%.*}
    pdftk $pdf_dir/*.pdf cat output ${out_name}_control.pdf
    randomised_list_of_pdfs=$(shuf -e $(echo $pdf_dir/*.pdf))
    pdftk $randomised_list_of_pdfs cat output $out_name.pdf
}

function set_pdf_password(){
    pdf_name=$1
    userpw=$2
    echo $userpw
    if [ ! "$userpw" = "" ]; then
        mv $pdf_name temp.pdf
        pdftk temp.pdf output $pdf_name user_pw $userpw
        rm temp.pdf
    fi
}

function delete_thumbnails(){
    dir_to_delete=$1
    rm -rf $dir_to_delete
}

function main(){
    image_dir=$1
    pdf_password=$2
    calling_dir=$(pwd)
    thumbnail_dir="./thumb"
    output_file_name=charisma_members.pdf
    
    delete_old_pdf $output_file_name
    echo "changing to working dir ${image_dir}"
    cd $image_dir
    delete_old_pdf $output_file_name
    create_dir_if_nonexistent $thumbnail_dir
    create_downsized_images_in_parallel $thumbnail_dir
    concatenate_pdfs $thumbnail_dir $output_file_name
    set_pdf_password $output_file_name $pdf_password
    mv *.pdf $calling_dir/
    delete_thumbnails $thumbnail_dir
    cd $calling_dir
}

image_dir=${1:-.}
pdf_password=${2:-''}
main $image_dir $pdf_password
