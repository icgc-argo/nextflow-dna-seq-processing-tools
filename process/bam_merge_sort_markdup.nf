#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = "0.1.4.1"
params.output_format = ['cram'] // options are ['cram', 'bam']

// optional process inputs
params.markdup = 'OPTIONAL_INPUT'
params.lossy = 'OPTIONAL_INPUT'

def generateCmdArgsFromParams() {
    cmdArgs = ""

    // process optional inputs
    cmdArgs = params.markdup != 'OPTIONAL_INPUT' ? "${cmdArgs} -d" : cmdArgs
    cmdArgs = params.lossy != 'OPTIONAL_INPUT' ? "${cmdArgs} -l" : cmdArgs

    // required args
    cmdArgs = "$cmdArgs -o ${params.output_format.join(' ')}"
    cmdArgs = "$cmdArgs -n $params.cpus"

    // return trimmed cmd
    return cmdArgs.trim()
}

process bamMergeSortMarkdup {

    container "quay.io/icgc-argo/bam-merge-sort-markdup:bam-merge-sort-markdup.${params.container_version}"

    label "mergeMarkdup"

    cpus params.cpus
    memory "${params.mem} MB"

    input:
        path aligned_lane_bams
        path ref_genome
        val aligned_basename

    output:
        path "${aligned_basename}.*", emit: merged_aligned_file

    script:
    ref = ref_genome.collectEntries { [(it.getExtension()) : it] }
    """
    bam-merge-sort-markdup.py -i $aligned_lane_bams -r $ref.fa -b $aligned_basename -n $params.cpus ${generateCmdArgsFromParams()}
    """
}
