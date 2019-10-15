#!/bin/bash
#===========================================================
# This script takes raw (Level_0) PDS files and converts them into Level_1 ISIS cubes
# NOTE: THIS LEVEL CONVENTION IS NOT THE SAME AS THE ISIS CASSINI ISS CONVENTION
# LEVEL 0 -> RAW PDS IMAGES
# LEVEL 1 -> ISIS INGESTION AND SPICE
# LEVEL 2 -> RADIOMETRIC AND PHOTOMETRIC CORRECTIONS
# LEVEL 3 -> NOISE REMOVAL
# LEVEL 4 -> MAP PROJECTED IMAGE

# Call Example: ./parallel_isis_level_1_processing ch4_js 433xxxx
#===========================================================

#====================================
# Save command line args in variables
#====================================
filter=$1
dataset=$2

#==========================
# Setup default directories
#==========================
#=== "FROM" Directory ===#
level_0_dir="/mnt/md1200/blalock/Voyager/ISS_Saturn_Observation/Level_0/$filter/$dataset"

#=== "TO" Directory ===#
level_1_dir="/mnt/md1200/blalock/Voyager/ISS_Saturn_Observation/Level_1/$filter/$dataset"
	#=== Make sure "TO" directory exists ===#
	mkdir -pv $level_1_dir
	
#===================================
# Cleanup old file in "TO" directory
#===================================
echo $level_1_dir/*.cub | xargs rm -v
echo $level_1_dir/*.png | xargs rm -v
echo $level_1_dir/*.tar.gz | xargs rm -v

#==========================================================
# Create file lists for parallel processing based on camera
#==========================================================
#=== Cleanup old lists ===#
echo $level_0_dir/*parallel*list*.txt | xargs rm -v
echo $level_1_dir/*parallel*list*.txt | xargs rm -v

echo "Creating parallel lists in $filter $dataset"
#=== Create list for only .imq images ===#
for i in $(ls $level_0_dir/c[0-9]*.imq)
do
	base_name=$(basename $i .imq)
		
	imq_file="$level_0_dir/$base_name.imq"
	cub_file="$level_1_dir/$base_name.cub"
	rrx_file="$level_1_dir/$base_name.rrx.cub"
	tar_file="$level_1_dir/$base_name.level1.tar.gz"
		
	echo $base_name >> $level_0_dir/parallel_basename_list.txt
	echo $imq_file >> $level_0_dir/parallel_imq_list.txt
	echo $cub_file >> $level_1_dir/parallel_imq_cub_list.txt
	echo $rrx_file >> $level_1_dir/parallel_imq_rrx_list.txt
	echo $tar_file >> $level_1_dir/parallel_tar_list.txt		
done

#=== Create list for only .img images ===#
for i in $(ls $level_0_dir/c[0-9]*.img)
do
	base_name=$(basename $i .img)
		
	img_file="$level_0_dir/$base_name.img"
	cub_file="$level_1_dir/$base_name.cub"
	rrx_file="$level_1_dir/$base_name.rrx.cub"
	tar_file="$level_1_dir/$base_name.level1.tar.gz"
		
	echo $base_name >> $level_0_dir/parallel_basename_list.txt
	echo $img_file >> $level_0_dir/parallel_img_list.txt
	echo $cub_file >> $level_1_dir/parallel_img_cub_list.txt
	echo $rrx_file >> $level_1_dir/parallel_img_rrx_list.txt
	echo $tar_file >> $level_1_dir/parallel_tar_list.txt		
done

#==============
# Process files
#==============
echo "Level 1 Processing images in $filter $dataset"
#=== Run voy2isis/pds2isis ===#
parallel --gnu --verbose --xapply voy2isis from={1} to={2} -verbose :::: $level_0_dir/parallel_imq_list.txt :::: $level_1_dir/parallel_imq_cub_list.txt

parallel --gnu --verbose --xapply pds2isis from={1} to={2} -verbose :::: $level_0_dir/parallel_img_list.txt :::: $level_1_dir/parallel_img_cub_list.txt

#=== Run spiceinit ===#
parallel --gnu --verbose --xapply spiceinit from={1} ckpredicted=true cknadir=true spkpredicted=true -verbose :::: $level_1_dir/parallel_imq_cub_list.txt

parallel --gnu --verbose --xapply spiceinit from={1} ckpredicted=true cknadir=true spkpredicted=true -verbose :::: $level_1_dir/parallel_img_cub_list.txt

#=== Run findrx ===#
parallel --gnu --verbose --xapply findrx from={1} -verbose :::: $level_1_dir/parallel_imq_cub_list.txt

parallel --gnu --verbose --xapply findrx from={1} -verbose :::: $level_1_dir/parallel_img_cub_list.txt

#=== Run remrx ===#
parallel --gnu --verbose --xapply remrx from={1} to={2} :::: $level_1_dir/parallel_imq_cub_list.txt :::: $level_1_dir/parallel_imq_rrx_list.txt

parallel --gnu --verbose --xapply cp -v {1} {2} :::: $level_1_dir/parallel_imq_rrx_list.txt :::: $level_1_dir/parallel_imq_cub_list.txt

parallel --gnu --verbose --xapply remrx from={1} to={2} :::: $level_1_dir/parallel_img_cub_list.txt :::: $level_1_dir/parallel_img_rrx_list.txt

parallel --gnu --verbose --xapply cp -v {1} {2} :::: $level_1_dir/parallel_img_rrx_list.txt :::: $level_1_dir/parallel_img_cub_list.txt

rm -v $level_1_dir/*.rrx.cub

#=== Compress and tarball ===#
cd $level_1_dir
pwd
		
parallel --gnu --verbose --xapply tar czvf {1} {2}* :::: $level_1_dir/parallel_tar_list.txt :::: $level_0_dir/parallel_basename_list.txt
		
cd -
		
#=== Cleanup files ===#
echo $level_1_dir/*.cub | xargs rm -v

