#!/usr/bin/sh

release_date=`cat $1 | grep SeqReleaseDate summary | sed -rn 's/.*([0-9]{4})\/([0-9]{2})\/([0-9]{2}).*/\1\2\3/p'`
species=`cat $1 grep SpeciesName summary | sed -rn 's/.*>(.*)<.*/\1/p'`
dl_link=`cat $1 | grep FtpPath_Assembly_rpt summary | sed -rn 's/.*>(.*)_assembly_report.txt.*/\1_genomic.fna.gz/p'`
assembly_report=`cat $1 | grep FtpPath_Assembly_rpt summary | sed -rn 's/.*>(.*)<.*/\1/p'`
echo "$release_date,$species,$dl_link,$assembly_report" > genome_info.csv