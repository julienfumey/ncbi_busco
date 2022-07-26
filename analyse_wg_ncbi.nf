params.groupe='Mammalia'

groupe=params.groupe

process listGenome{
    label 'ncbi'

    input:
    val groupToStudy from groupe

    output:
    file('uid_list.txt') into list_id

    script:
    '''
    esearch -db assembly -query ${groupToStudy} | efetch -format uid > uid_list.txt
    '''
}

list_id.splitText().into(ids)

process getDownloadLink{
    label 'ncbi'

    input:
    val(genomeId) from ids

    output:
    file('*info.csv') into all_info, all_info2, all_info3
    tuple env(release_date), env(species), env(dl_link), env(assembly_report) into infoSpecies


    shell:
    '''
    esummary -db assembly -id !{genomeId} > summary
    if grep -q "FtpPath_Assembly_rpt" summary
        then
        echo "toto"
    fi
    '''
}

all_info.collectFile(name: 'All_infos.csv').subscribe{
    f -> f.copyTo(results.resolve(f.name))
}

process removeAltGenome{
    publishDir "${results}", mode: 'link'
    input:
    file(in) from all_info2.collectFile(name: 'All_infos.csv')

    output:
    file('NoAlt_All_infos.csv') into all_info_noalt, all_info_noalt2

    script:
    """
    grep -v "alt_assembly" $in > NoAlt_All_infos.csv
    """
}

process createUniqSpeciesFile{
    input:
    file(in) from all_info_noalt

    output:
    file('uniq_species.txt') into uniq_species

    script:
    """
    cut -f 2 $in | sort | uniq > uniq_species.txt
    """
}

uniq_species.splitText().into(species)

process selectGenomeToDL{
    input:
    val(spName) from species
    file(noalt) from all_info_noalt2

    output:
    file(*.fna.gz) into fastagzipfile

    shell:
    '''
    genome=`selectGenomeFile.py !{spName} !{noalt}`
    '''

}