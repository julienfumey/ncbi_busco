params.groupe='Mammalia'
params.workpath='/pasteur/appa/scratch/jfumey/busco/'
//params.resultspath='/pasteur/appa/homes/jfumey/didier/busco_try/'
params.resultspath='/pasteur/appa/scratch/jfumey/busco/results/'
params.ncbiapikey="84413ef210acc86d928b322060eb89aa1808"
params.buscoRefFile="mammalia_odb10"
params.buscoDLpath="/pasteur/appa/homes/jfumey/busco/busco_downloads/"

groupe=params.groupe
resultsDir=params.resultspath
ncbiapikey=params.ncbiapikey
buscoRefFile=file(params.buscoRefFile)
buscoDLpath=params.buscoDLpath

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
    publishDir "${resultsDir}/01_genome_summary", mode: 'copy'
    label 'ncbi'

    maxForks = 10

    input:
    val(genomeId) from ids1

    output:
    file('*summary.txt') into summary

    script:
    """
    export NCBI_API_KEY=$ncbiapikey
    esummary -db assembly -id ${genomeId} > ${genomeId}_summary.txt
    sleep 1
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
    if grep -q suppressed ${s}
        then
        touch nogenome.csv
    elif grep -q FtpPath_Assembly_rpt ${s}
        then
        selectDLlink.sh ${s} > genome_info.csv
    else
        touch nogenome.csv
    fi
    """
}

process gatherGenomeInfo{
    publishDir "${resultsDir}/Info", mode:'copy'

    input:
    file(allinfo) from all_info3.collectFile()

    output:
    file "info_all_genome.txt" into all_info_publish

    script:
    """
    cat ${allinfo} > info_all_genome.txt
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
    maxForks 1

    input:
    val(spName) from species1
    each file(noalt) from all_info_noalt2

    output:
    file('genome_file_info.csv') into genomeInfo
    tuple val(spName), file('*.fna.gz') into fastaFile
    tuple val(spName), file('*_report.txt') into reportFile

    shell:
    '''
    selectGenome.sh "!{spName}" !{noalt} > genome_file_info.csv
    '''

}

process unzipFasta{

    input:
    tuple val(spName), file(fasta) from fastaFile

    output:
    tuple val(spName), file('unzip.fasta') into fastaUnzipped, fastaUnzipped2

    script:
    """
    gunzip -k -c ${fasta} > unzip.fasta
    """
}

process checkforAltScaffold{
    publishDir "${resultsDir}/Info", pattern: '*_info_removed_genome_parts.txt' , mode: 'copy'

    input:
    tuple val(spName), file(report) from reportFile
   

    output:
    file('modified_genome.txt') optional true into listofModifiedGenome
    file('good_scaffold_list.txt') optional true into listGoodScaffold
    file("${report.baseName}_info_removed_genome_parts.txt") optional true into listRemovedGenomeParts
    file("notrim.txt") optional true into notrim

    script:
    """
    if grep -q alt-scaffold $report
        then 
            echo ${spName} > modified_genome.txt
            listGoodScaffold.sh ${report} > good_scaffold_list.txt
            listRemovedGenomeParts.sh ${report} > ${report.baseName}_info_removed_genome_parts.txt
        else
            touch notrim.txt
    fi   
    """

}

process publishModified{
    publishDir "${resultsDir}/Info", mode:'copy'

    input:
    file modified from listofModifiedGenome.collectFile()

    output:
    file "modifiedGenome.txt" into modified_genome

    script:
    """
    cat ${modified} > modifiedGenome.txt
    """
}


process removeAltScaffold{
    label 'samtools'

    input:
    tuple val(spName), file(infasta) from fastaUnzipped
    file(goodScaffold) from listGoodScaffold

    output:
    tuple val(spName), file('genome_trimmed.fasta') into trimmedFasta

    script:
    """
    samtools faidx ${infasta} < ${goodScaffold} > genome_trimmed.fasta
    """
}



process busco{
    publishDir "${resultsDir}/results/${spName}/", mode:'copy'
    label 'busco'

    maxForks 5

    input:
    each file(buscoref) from buscoRefFile
    tuple val(spName), file(fastaUnzipped) from ( notrim ? fastaUnzipped2 : trimmedFasta )

    output:
    tuple file('*.tsv'), file('*.txt') into buscoresults
 
    script:
    """
    busco -i ${fastaUnzipped} -m genome -o ${spName.replaceAll(/\s/,'_')} -l ${buscoref} --download_path ${buscoDLpath} -c 45 --offline -f --metaeuk_parameters='--remove-tmp-file=1' --metaeuk_rerun_parameters='--remove-tmp-files=1'
    """
}
