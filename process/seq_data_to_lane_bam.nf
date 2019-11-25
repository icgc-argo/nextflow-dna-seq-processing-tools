#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = "0.1.5.0"
params.reads_max_discard_fraction = 0.05

process seqDataToLaneBam {

    container "quay.io/icgc-argo/seq-data-to-lane-bam:seq-data-to-lane-bam.${params.container_version}"

    tag "${seq}"

    input:
        tuple path(seq_rg_json), path(seq)

    output:
        path '*.lane.bam', emit: unaligned_lanes

    """
    export TMPDIR=\$PWD
    seq-data-to-lane-bam.py -p ${seq_rg_json} -d ${seq} -m ${params.reads_max_discard_fraction}
    """
}
