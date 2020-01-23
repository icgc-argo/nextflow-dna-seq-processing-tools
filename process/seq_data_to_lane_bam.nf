#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = "0.2.0.0"
params.reads_max_discard_fraction = -1
params.tool = ""

process seqDataToLaneBam {

    container "quay.io/icgc-argo/seq-data-to-lane-bam:seq-data-to-lane-bam.${params.container_version}"

    label "seqToLane"

    cpus params.cpus
    memory "${params.mem} MB"

    input:
        tuple path(seq_meta_json), path(seq)

    output:
        path '*.lane.bam', emit: unaligned_lanes

    script:
    reads_max_discard_fraction = params.reads_max_discard_fraction < 0 ? 0.05 : params.reads_max_discard_fraction
    arg_tool = params.tool != "" ? "-t ${params.tool}" : ""
    """
    seq-data-to-lane-bam.py \
      -p ${seq_meta_json} \
      -d ${seq} \
      -m ${reads_max_discard_fraction} \
      -n ${params.cpus} \
      ${arg_tool}
    """
}
