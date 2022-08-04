params.groupe='Mammalia'
params.workpath='/pasteur/appa/scratch/jfumey/busco/'
//params.resultspath='/pasteur/appa/homes/jfumey/didier/busco_try/'
params.resultspath='/pasteur/appa/scratch/jfumey/busco/results/'
params.ncbiapikey="84413ef210acc86d928b322060eb89aa1808"

groupe=params.groupe
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

list_id.splitText().map{it -> it.trim()}.into{ids1; ids2}

process getSummaryGenome{
    //publishDir "${resultsDir}/01_genome_summary", mode: 'link'
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
    //publishDir "${resultsDir}", mode: 'link'
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

process removeAltGenome{
    //publishDir "${resultsDir}", mode: 'link'
    input:
    file(in) from all_info2.collectFile()

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
    cut -d, -f 2 $in | sort | uniq > uniq_species.txt
    """
}

uniq_species.splitText(by:1).map{it -> it.trim()}.into{species1;species2}

process downloadGenome{
    //publishDir "${resultsDir}", mode: 'copy'
    label 'dl'
    executor 'local'
    input:
    val(spName) from species1
    each file(noalt) from all_info_noalt2

    output:
    file('genome_file_info.csv') into genomeInfo
    file('*.fna.gz') into fastaFile
    tuple val(spName), file('*._report.txt') into reportFile

    shell:
    '''
    `selectGenome.sh "!{spName}" !{noalt}` > genome_file_info.csv
    '''

}

process unzipFasta{

    input:
    file(fasta) from fastaFile

    output:
    file('*.fna') into fastaUnzipped, fastaUnzipped2

    script:
    """
    gzip -d ${fasta}
    """
}

process checkforAltScaffold{
    publishDir "${resultsDir}/Info", pattern: '*_info_removed_genome_parts.txt' , mode: 'copy'

    input:
    tuple val(spName), file(report) from reportFile
   

    output:
    file('modified_genome.txt') optional true into listofModifiedGenome
    file('good_scaffold_list.txt') optional true into listGoodScaffold
    file("${spName}_info_removed_genome_parts.txt") optional true into listRemovedGenomeParts
    file("notrim.txt") optional true into notrim

    script:
    """
    if grep -q alt-scaffold $report
        then 
            echo ${spName} >> modified_genome.txt
            listGoodScaffold.sh ${report} > good_scaffold_list.txt
            listRemovedGenomeParts.sh > ${spName}_info_removed_genome_parts.txt
        else
            touch notrim.txt     
    """

}

process removeAltScaffold{
    label 'samtools'

    input:
    file(infasta) from fastaUnzipped
    file(goodScaffold) from listGoodScaffold

    output:
    file('genome_trimmed.fasta') into trimmedFasta

    script:
    samtools faidx ${infasta} < ${goodScaffold} > genome_trimmed.fasta
}

/*
process busco{
    i

    script:
        
}
*/