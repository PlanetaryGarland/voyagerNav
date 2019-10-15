#!/bin/bash
#===========================================================
# This script takes raw (Level_1) PDS files and converts them into Level_2 ISIS cubes
# NOTE: THIS LEVEL CONVENTION IS NOT THE SAME AS THE ISIS CASSINI ISS CONVENTION
# LEVEL 0 -> RAW PDS IMAGES
# LEVEL 1 -> ISIS INGESTION AND SPICE
# LEVEL 2 -> RADIOMETRIC AND PHOTOMETRIC CORRECTIONS
# LEVEL 3 -> NOISE REMOVAL
# LEVEL 4 -> MAP PROJECTED IMAGE

# Call Example: ./isis_level_1_processing.sh cb2cl2 1476 WAC
#===========================================================

level_0_dir="/mnt/md1200/blalock/Voyager/ISS_Saturn_Observation/Level_0"

rm -v $level_0_dir/*parallel*.txt

#=== Make parallel imq lists ===#

for i in $(ls $level_0_dir/*.imq)
do
	base_name=$(basename $i .imq)
		
	imq_file="$level_0_dir/$base_name.imq"
	cub_file="$level_0_dir/$base_name.cub"
	label_file="$level_0_dir/$base_name.label.txt"
	
	echo $imq_file >> $level_0_dir/parallel_imq_list.txt
	echo $cub_file >> $level_0_dir/parallel_cub_list.txt
	echo $label_file >> $level_0_dir/parallel_label_list.txt		
done

parallel --gnu --verbose --xapply voy2isis from={1} to={2} -verbose :::: $level_0_dir/parallel_imq_list.txt :::: $level_0_dir/parallel_cub_list.txt

parallel --gnu --verbose --xapply spiceinit from={1} ckpredicted=yes spkpredicted=yes -verbose :::: $level_0_dir/parallel_cub_list.txt

parallel --gnu --verbose --xapply catoriglab from={1} to={2} append=false -verbose :::: $level_0_dir/parallel_cub_list.txt :::: $level_0_dir/parallel_label_list.txt

parallel --gnu --verbose --xapply rm -v {1} :::: $level_0_dir/parallel_cub_list.txt

#=== Make parallel imq lists ===#

rm -v $level_0_dir/*parallel*.txt

for i in $(ls $level_0_dir/*.img)
do
	base_name=$(basename $i .img)
		
	img_file="$level_0_dir/$base_name.img"
	bad_imq_file="$level_0_dir/$base_name.imq"
	cub_file="$level_0_dir/$base_name.cub"
	label_file="$level_0_dir/$base_name.label.txt"
	
	echo $img_file >> $level_0_dir/parallel_img_list.txt
	echo $bad_imq_file >> $level_0_dir/parallel_bad_imq_list.txt
	echo $cub_file >> $level_0_dir/parallel_cub_list.txt
	echo $label_file >> $level_0_dir/parallel_label_list.txt		
done

parallel --gnu --verbose --xapply pds2isis from={1} to={2} -verbose :::: $level_0_dir/parallel_img_list.txt :::: $level_0_dir/parallel_cub_list.txt

parallel --gnu --verbose --xapply spiceinit from={1} ckpredicted=yes spkpredicted=yes -verbose :::: $level_0_dir/parallel_cub_list.txt

parallel --gnu --verbose --xapply catoriglab from={1} to={2} append=false -verbose :::: $level_0_dir/parallel_cub_list.txt :::: $level_0_dir/parallel_label_list.txt

parallel --gnu --verbose --xapply rm -v {1} :::: $level_0_dir/parallel_cub_list.txt

parallel --gnu --verbose --xapply cp -v {1} $level_0_dir/bad_imq_files :::: $level_0_dir/parallel_bad_imq_list.txt

parallel --gnu --verbose --xapply rm -v {1} :::: $level_0_dir/parallel_bad_imq_list.txt
