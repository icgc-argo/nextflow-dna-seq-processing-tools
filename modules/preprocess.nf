#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024
params.reads_max_discard_fraction = 0.05

process extractJSONValues {
    container 'cfmanteiga/alpine-bash-curl-jq'

    input:
    val json

    """
    jq '.aligned_basename' ${json}
    """
}

process seqDataToLane {

    container 'quay.io/icgc-argo/seq-data-to-lane-bam:seq-data-to-lane-bam.0.1.3'

    tag "${seq_rg_json} -- ${seq}"

    input:
    file seq_rg_json
    file seq

    output:
    file '*.lane.bam'

    """
    seq-data-to-lane-bam.py -p ${seq_rg_json} -d ${seq} -m ${params.reads_max_discard_fraction}
    """
}