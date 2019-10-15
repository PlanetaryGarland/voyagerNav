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
level_1_dir="/mnt/md1200/blalock/Voyager/ISS_Saturn_Observation/Level_1/$filter/$dataset"

#=== "TO" Directory ===#
level_2_dir="/mnt/md1200/blalock/Voyager/ISS_Saturn_Observation/Level_2/$filter/$dataset"
	#=== Make sure "TO" directory exists ===#
	mkdir -pv $level_2_dir
	
#===============================================	
# Setup photometric correction PVL path and name
#===============================================
pvls_path="/mnt/md1200/blalock/Voyager/ISS_Saturn_Observation/Isis_Photometric_Corrections"
pvl_file="$pvls_path/voyager_iss_$filter.pvl"

#===================================
# Cleanup old file in "TO" directory
#===================================
echo $level_2_dir/*.cal.cub | xargs rm -v
echo $level_2_dir/*.pho.cub | xargs rm -v
echo $level_2_dir/*.tar.gz | xargs rm -v

#===================================
# Extract files from Level_1 tarball
#===================================
cd $level_1_dir

for i in $(ls $level_1_dir/*.tar.gz)
do
	tar zxvf $i
done

cd -

#===========================================
# Create file lists for parallel processing 
#===========================================
#=== Cleanup old lists ===#
echo $level_1_dir/*parallel*list*.txt | xargs rm -v
echo $level_2_dir/*parallel*list*.txt | xargs rm -v

echo "Creating parallel lists in $filter $dataset"
#=== Create list for only WAC images ===#	
for i in $(ls $level_1_dir/c[0-9]*.cub)
do
	base_name=$(basename $i .cub)
		
	cub_file="$level_1_dir/$base_name.cub"
	cal_file="$level_2_dir/$base_name.cal.cub"
	pho_file="$level_2_dir/$base_name.pho.cub"
	tar_file="$level_2_dir/$base_name.level2.tar.gz"
		
	echo $base_name >> $level_1_dir/parallel_basename_list.txt
	echo $cub_file >> $level_1_dir/parallel_cub_list.txt
	echo $cal_file >> $level_2_dir/parallel_cal_list.txt
	echo $pho_file >> $level_2_dir/parallel_pho_list.txt
	echo $tar_file >> $level_2_dir/parallel_tar_list.txt		
done

#==============
# Process files
#==============
echo "Level 2 Processing images in $filter $dataset"

#=== Run ciss2isis ===#
parallel --gnu --verbose --xapply voycal from={1} to={2} -verbose :::: $level_1_dir/parallel_cub_list.txt :::: $level_2_dir/parallel_cal_list.txt

#=== Run photomet ===#
parallel --gnu --verbose --xapply photomet from={1} to={2} maxemission=87.0 maxincidence=87.0 frompvl=$pvl_file -verbose :::: $level_2_dir/parallel_cal_list.txt :::: $level_2_dir/parallel_pho_list.txt

#=== Compress and tarball ===#
#cd $level_2_dir
#pwd
		
#parallel --gnu --verbose --xapply tar czvf {1} {2}* :::: $level_2_dir/parallel_tar_list.txt :::: $level_1_dir/parallel_basename_list.txt
		
#cd -

#=== Cleanup files ===#
#echo $level_1_dir/*.cub | xargs rm -v
#echo $level_2_dir/*.cub | xargs rm -v

