for i in $(ls *.imq)
do
	base_name=$(basename $i .imq)
		
	imq_file="$base_name.imq"
	rrx_file="$base_name.rrx.cub"
	cub_file="$base_name.cub"
	cal_file="$base_name.cal.cub"
	pho_file="$base_name.pho.cub"
	label_file="$base_name.label.txt"
	
	voy2isis from=$imq_file to=$cub_file
	
	spiceinit from=$cub_file ckpredicted=yes spkpredicted=yes
	
	caminfo from=$cub_file to=$label_file isislabel=yes originallabel=yes statistics=yes camstats=yes
	
	findrx from=$cub_file
	
	remrx from=$cub_file to=$rrx_file
	
	voycal from=$rrx_file to=$cal_file
		
		
done
