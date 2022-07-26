#! /usr/bin/Python3

import argparse

parser = argparse.ArgumentParser(
        description='Given species name and a list of genome from NCBI, select the best file to DL', 
        formatter_class=ArgumentAdvancedDefaultsHelpFormatter
    )

parser.add_argument('--species', nargs='*', help='Species name')
parser.add_argument('--genome liste', nargs='*', help='File containing the genome list')

args = parser.parse_args()

