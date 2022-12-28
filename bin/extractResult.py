#! /usr/bin/Python3

import json
import argparse

parser = argparse.ArgumentParser(
        description='Parse input file from Busco to the output file', 
    )

parser.add_argument('--input', help='Input file')
parser.add_argument('--species', help='Species name')
parser.add_argument('--genomeFile', help='Name of the genome file')
parser.add_argument('--output', help='output file (csv format)')
args = parser.parse_args()

#open json file and load it
data_dict = {}
with open(args.input) as result_file:
        line = result_file.readline()
        while line:
            linestrp = line.strip()
            if linestrp.startswith('#') or linestrp == '':
                pass
            else:
                if linestrp.startswith('C:') or linestrp == "***** Results: *****" or linestrp.startswith("Assembly"):
                    pass
                elif linestrp == "Dependencies and versions:":
                    break
                else:
                    linesplt = linestrp.split('\t')
                    data_dict[linesplt[1]] = linesplt[0]
            line = result_file.readline()

with open(args.output, 'w') as fhout:
    fhout.write("'Species','Genome file','Busco groups searched','Total length','Perc gaps','Scaffold N50','Contigs N50','Complete','Perc complete','Single copy','Perc single copy','Duplicated','Perc duplicated','Fragmented','Perc fragmented','Missing','Perc missing'\n")
    strToWrite = f"'{args.species}'"
    strToWrite += f",'{args.genomeFile}'"
    strToWrite += f",'{data_dict['Total BUSCO groups searched']}'"
    strToWrite += f",'{data_dict['Total length']}'"
    strToWrite += f",'{data_dict['Percent gaps']}'"
    strToWrite += f",'{data_dict['Scaffold N50']}'"
    strToWrite += f",'{data_dict['Contigs N50']}'"
    strToWrite += f",'{data_dict['Complete BUSCOs (C)']}'"
    strToWrite += f",'{int(data_dict['Complete BUSCOs (C)'])/int(data_dict['Total BUSCO groups searched'])}'"
    strToWrite += f",'{data_dict['Complete and single-copy BUSCOs (S)']}'"
    strToWrite += f",'{int(data_dict['Complete and single-copy BUSCOs (S)'])/int(data_dict['Total BUSCO groups searched'])}'"
    strToWrite += f",'{data_dict['Complete and duplicated BUSCOs (D)']}'"
    strToWrite += f",'{int(data_dict['Complete and duplicated BUSCOs (D)'])/int(data_dict['Total BUSCO groups searched'])}'"
    strToWrite += f",'{data_dict['Fragmented BUSCOs (F)']}'"
    strToWrite += f",'{int(data_dict['Fragmented BUSCOs (F)'])/int(data_dict['Total BUSCO groups searched'])}'"
    strToWrite += f",'{data_dict['Missing BUSCOs (M)']}'"
    strToWrite += f",'{int(data_dict['Missing BUSCOs (M)'])/int(data_dict['Total BUSCO groups searched'])}'\n"
    
    fhout.write(strToWrite)    