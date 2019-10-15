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

for i in $(ls $level_0_dir/*.imq)
do
	base_name=$(basename $i .imq)
		
	imq_file="$level_0_dir/$base_name.imq"
	cub_file="$level_0_dir/$base_name.cub"
	label_file="$level_0_dir/$base_name.label.txt"
	
	voy2isis from=$imq_file to=$cub_file -verbose
	
	spiceinit from=$cub_file ckpredicted=yes spkpredicted=yes -verbose
	
	caminfo from=$cub_file to=$label_file originallabel=yes -verbose
	
	rm -v $cub_file		
done
