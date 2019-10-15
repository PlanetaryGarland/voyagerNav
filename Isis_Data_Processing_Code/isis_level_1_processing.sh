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

for i in $(ls *.imq)
do
	base_name=$(basename $i .imq)
		
	imq_file="$base_name.imq"
	rrx_file="$base_name.rrx.cub"
	cub_file="$base_name.cub"
	label_file="$base_name.label.txt"
	
	voy2isis from=$imq_file to=$cub_file
	
	spiceinit from=$cub_file ckpredicted=yes spkpredicted=yes
	
	findrx from=$cub_file
	
	remrx from=$cub_file to=$rrx_file		
done
