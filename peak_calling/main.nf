
nextflow.enable.strict = true

if( !nextflow.version.matches('>=23.10') ) {
    println "This workflow requires Nextflow version 23.10 or greater current version is $nextflow.version"
    exit 1
}

params.help = ""
RED='\033[0;31m'

if (params.help) {
    help()
    exit(0)
}

def help() {
log.info """
        =============================================
        NDN H Y D R A   F A S T Q C   P I P E L I N E
  
         Usage:
        ---------------------------------------------
         --help             : All input options
         --input            : File location in ndn hydra cluster, expected "*.fastq.gz"
         --outDir           : Directory in which files to be stored (local) after fetching from ndn hydra 
         --result           : Directory where fastqc output will be stored (local), expected "*_fastqc.{zip,html}"
         -profile conda     : To install fastqc on conda environment
         -entry fetch_hydra : Run a workflow to fetch the data from ndn hydra cluster to local machie
         -entry compute_data: Run a workflow that will compute the fastqc and the result uploaded to ndn hydra cluster 
        =============================================
         """
         .stripIndent()

}


params.input = ''
input_ch = Channel.value(params.input)

params.outDir = ''

include { Hydra_fetch } from './fetch_module.nf'
include { Hydra_insert } from './insert_module.nf'

params.result = ''

if ( (params.input.length() == 0) || (params.outDir.length() == 0) || (params.result.length() == 0) ) {

	println "$RED -------------------------------------------------------------------------------------------------"
	println "--input=<dir>, --outDir=<dir>, --result=<dir>, are the required arguments. --help for more details"
	println "------------------------------------------------------------------------------------------------------"
	exit(0)
}

log.info """
         =============================================
         NDN H Y D R A   F A S T Q C   P I P E L I N E

         Parameters:
         ---------------------------------------------
         --input            : $params.input	(ndn hydra)
         --outDir           : $params.outDir	(local)
         --result           : $params.result	(local)
         --result (default) : $projectDir	(local)
         =============================================
         """
         .stripIndent()



process compute {
	publishDir params.result
		
	input:
	path file_name

	output:
	path "*_fastqc.{zip,html}"

	script:
        """
        fastqc -q $file_name
        """
}

process align {
	publishDir params.result

	input: 
	tuple val(sample_id), path(reads)


	output:
	path("${sample_id}.bam")

	script:
	"""
	bowtie2 --large-index -p 3 -q --local -x "/home/ubuntu/hg38/hg38" -1 ${reads[0]} -2 ${reads[1]} | samtools view -h -S -b -@ 3 - > ${sample_id}.bam 
	"""
	
}

process redundant {
        publishDir params.result

        input:
	path(bamfile)

        output:
        path("${bamfile[0].baseName}.aligned.bam")

        script:
        """
        sambamba view -h -t 2 -f bam -F "[XS] == null and not unmapped  and not duplicate" ${bamfile[0].baseName}.bam > ${bamfile[0].baseName}.aligned.bam
        """
}

process sort {
	publishDir params.result

	input:
	path(reads)

	output:
	tuple path("${reads.baseName}.sorted.bam"), path("${reads.baseName}.sorted.bam.bai")

	script:
	"""
	sambamba sort -t 3 ${reads}
	"""
}


process peakCalling {
        publishDir params.result

        input:
        path(bamfile)

        output:
        path("${bamfile[0].baseName}_*.*")

        script:
        """
        macs3 callpeak -t ${bamfile[0].baseName}.bam -f BAM -g hs -n ${bamfile[0].baseName}
        """

}

workflow fetch_hydra {
	input_files = Hydra_fetch(params.input, params.outDir)
}

workflow compute_data {
	output_ch = Channel.fromPath("$params.outDir/*.gz")
	//result_files = compute(output_ch.collect())
	
	fastq_files = Channel.fromFilePairs("$params.outDir/*{1,2}.fastq.gz")
        

    	out = align(fastq_files)
	sorted = sort(out)
	remove_redundant = redundant(sorted)
        peak_output = peakCalling(remove_redundant)

	output_hydra = Hydra_insert(peak_output, params.input)
	//output_hydra.view()
}

workflow {
	fetch_hydra()
	compute_data()
}

workflow.onComplete {
    println "#####################################################"
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
