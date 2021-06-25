
#usage, receives a file with a list of significant sites from different FORGE2 runs as input, give it e.g. sig.sites.erc as $1

#a typical line from this file will look like:

#filename:Zscore Pvalue Cell Tissue Datatype File Probe Accession Qvalue
#erc/0xFFC4C82ED3C111E9AB004FF224AE50B3/Highest_math_class_taken_MTAG.GWAS.erc.chart.tsv.gz:67:5.170 5.63e-07 Fetal_Brain Fetal Brain DHS UW.Fetal_Brain.ChromatinAccessibility.H-24297.DS20226.twopass.merge150.wgt10.zgt2.wig.gz rs10411759,rs10510388,rs10740140,rs10846491,rs10922907,rs11040813,rs11075624,rs11243638,rs11264489,rs11588857,rs11714441,rs11729053,rs11775314,rs118134876,rs1182532,rs11864750,rs12151113,rs12306290,rs12552288,rs12586987,rs12653396,rs12670901,rs12761761,rs1291823,rs12938581,rs13014982,rs13020883,rs13256888,rs13274806,rs1329044,rs1355619,rs1418004,rs144876213,rs149914551,rs1506431,rs1553212,rs1555021,rs17262885,rs17669337,rs17782474,rs1989223,rs1998459,rs2160514,rs2237318,rs2275641,rs2279574,rs2425819,rs2447091,rs2472640,rs2582974,rs2604263,rs2629540,rs2748809,rs2892827,rs3128341,rs353490,rs35371013,rs35672602,rs3736166,rs3809634,rs3823036,rs4140762,rs4233210,rs4384309,rs4606978,rs4628086,rs4731415,rs4766424,rs4767921,rs4848924,rs56032805,rs56355754,rs6004882,rs6028083,rs60874983,rs61997667,rs6457996,rs6541988,rs6887429,rs6977237,rs73055556,rs737902,rs741813,rs75751670,rs7603132,rs76076331,rs7637427,rs767943,rs7728402,rs7803932,rs78116078,rs7934386,rs7977614,rs8058137,rs8061082,rs8067165,rs870589,rs890076,rs933738,rs9375403,rs9401101,rs944028,rs9574095,rs9977825GSM878651 4.21e-05

#subsets of the heatmaps can be easily created by subsetting the input file e.g. by:
#head -20 input.file > input.file.2
#and then reading input.file.2 into this bash script

sort -k10,10 -g $1 |grep -v "01$"|grep -v "02$"|awk -F":" '{print $1}'|sort|uniq > ls.sig.file

#unzip files

awk '{print "gunzip " $1}' ls.sig.file |bash

#update file

sed -i 's/.gz//g' ls.sig.file 

#make qval files

awk '{print "bash make.qval.file.sh " $1}' ls.sig.file |bash 

#concatenate qval files into a matrix

awk '{print $0".qvals"}' ls.sig.file > ls.sig.file.qvals

cat ls.sig.file.qvals |tr "\n" " "|xargs paste > $1.qvals



#delete header

tail -n +2 $1.qvals > $1.qvals.1

#add new header cols


awk -F"/" '{print $3}' ls.sig.file|awk -F".rsids" '{print $1}' |tr "\n" "\t" > cols.file

sed -i -e '$a\' cols.file

cat cols.file $1.qvals.1 > $1.qvals.2

#add rows

head -1 ls.sig.file |xargs cut -f3,4,6|tr "\t" " " > row.file

sed -i 's/ /_/g' row.file 

paste row.file $1.qvals.2 > $1.qvals.a

sed -i 's/\t$//g' $1.qvals.a 

#input this matrix into R to get a heatmap

Rscript ~/bin/heatmap.R $1.qvals.a

mv heatmap.pdf $1.heatmap.pdf





