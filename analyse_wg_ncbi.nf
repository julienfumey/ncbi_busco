params.groupe='Mammalia'
params.workpath='/pasteur/appa/scratch/jfumey/busco/'
params.resultspath='/pasteur/zeus/BioIT/jfumey/busco/'
params.ncbiapikey="84413ef210acc86d928b322060eb89aa1808"

groupe=params.groupe
workDir="${params.workpath}/work"
resultsDir=params.resultspath
ncbiapikey=params.ncbiapikey

process listGenome{
    label 'ncbi'

    input:
    val groupToStudy from groupe

    output:
    file('uid_list.txt') into list_id

    script:
    """
    export NCBI_API_KEY=$ncbiapikey
    esearch -db assembly -query ${groupToStudy} | efetch -format uid > uid_list.txt
    """
}

list_id.splitCsv(header=false, by:1).into{ids1; ids2}

process getSummaryGenome{
    publishDir "${resultsDir}/01_genome_summary", mode: 'link'
    label 'ncbi'

    input:
    val(genomeId) from ids1

    output:
    file('*summary.txt') into summary

    script:
    """
    export NCBI_API_KEY=$ncbiapikey
    esummary -db assembly -id ${genomeId} > ${genomeId}_summary.txt
    """
}

process getDownloadLink{
    publishDir "${resultsDir}", mode: 'link'
    label 'selectDLlink'

    input:
    file(s) from summary

    output:
    file('genome_info.csv') optional true into all_info, all_info2, all_info3
    file('nogenome.csv') optional true into nogenome

    script:
    """
    if grep -q FtpPath_Assembly_rpt ${s}
        then
        selectDLlink.sh ${s} > genome_info.csv
    else
        touch nogenome.csv
    fi
    """
}

all_info.collectFile(name: 'All_infos.csv').subscribe{
    f -> f.copyTo(results.resolve(f.name))
}

process removeAltGenome{
    publishDir "${resultsDir}", mode: 'link'
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
    publishDir "${resultsDir}", mode: 'link'

    input:
    file(in) from all_info_noalt

    output:
    file('uniq_species.txt') into uniq_species

    script:
    """
    cut -f 2 $in | sort | uniq > uniq_species.txt
    """
}

/*
uniq_species.splitText().into(species)

process selectGenomeToDL{
    input:
    val(spName) from species
    file(noalt) from all_info_noalt2

    output:
    file(*.fna.gz) into fastagzipfile

    script:
    """
    selectGenomeFile.py ${spName} ${noalt} > fileToDL
    """

}
*/