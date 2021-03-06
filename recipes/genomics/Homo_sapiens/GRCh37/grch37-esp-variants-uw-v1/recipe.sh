#!/bin/sh
set -eo pipefail -o nounset
wget --quiet http://evs.gs.washington.edu/evs_bulk_data/ESP6500SI-V2-SSA137.GRCh38-liftover.snps_indels.vcf.tar.gz

# extract individual chromosome files
tar -zxf ESP6500SI-V2-SSA137.GRCh38-liftover.snps_indels.vcf.tar.gz

# combine chromosome files into one 
(grep ^# ESP6500SI-V2-SSA137.GRCh38-liftover.chr1.snps_indels.vcf; cat ESP6500SI-V2-SSA137.GRCh38-liftover.chr*.snps_indels.vcf | grep ^[^#] ) > temp.vcf

# sort the chromosome data according to the .genome file from github
gsort temp.vcf https://raw.githubusercontent.com/gogetdata/ggd-recipes/master/genomes/Homo_sapiens/GRCh37/GRCh37.genome \
    | bgzip -c > ESP6500SI.all.snps_indels.vcf.gz

# tabix it
tabix -p vcf ESP6500SI.all.snps_indels.vcf.gz

# get handle for reference file
reference_fasta="$(ggd list-files 'grch37-reference-genome-1000g-v1' -s 'Homo_sapiens' -g 'GRCh37' -p 'grch37-reference-genome-1000g-v1.fa')"

# get the santizer script
wget --quiet https://raw.githubusercontent.com/arq5x/gemini/master/gemini/annotation_provenance/sanitize-esp.py

# sanitize
zless ESP6500SI.all.snps_indels.vcf.gz | python sanitize-esp.py | bgzip -c > temp.gz
tabix temp.gz

# decompose with vt
vt decompose -s temp.gz \
    | vt normalize -r "$reference_fasta" - \
    |  perl -pe 's/\([EA_|T|AA_]\)AC,Number=R,Type=Integer/\1AC,Number=R,Type=String/' \
    | bgzip -c > grch37-esp-variants-uw-v1.vcf.gz 

tabix grch37-esp-variants-uw-v1.vcf.gz

# clean up environment
rm ESP6500SI-V2-SSA137.GRCh38-liftover.snps_indels.vcf.tar.gz
rm ESP6500SI-V2-SSA137.GRCh38-liftover.chr*.snps_indels.vcf
rm ESP6500SI.all.snps_indels.vcf.gz.tbi
rm ESP6500SI.all.snps_indels.vcf.gz
rm sanitize-esp.py
rm temp.gz
rm temp.gz.tbi
rm temp.vcf
