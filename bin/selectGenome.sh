#!/usr/bin/sh


#$1 == species
#$2 == allinfo

number_GCF=`grep ",$1," $2 | grep -c "\/GCF\/"`

line=$(
    if [ $number_GCF -ge 1 ]
        then 
            grep ",$1," $2 | grep "\/GCF\/" | sort -k1 -n | tail -1
        else 
            grep ",$1," $2 | sort -k1 -n | tail -1
    fi)

echo "$line"

genome_link=`echo $line | cut -f3 -d,`
report_link=`echo $line | cut -f4 -d,`

wget -q $genome_link
wget -q $report_link