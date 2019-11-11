#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = '0.1.3'

process sequenceValidation {

    container "quay.io/icgc-argo/seq-validation:seq-validation.${params.container_version}"

    tag "${seq_rg_json} -- ${seq}"

    input:
    file seq_rg_json
    file seq

    output:
    stdout()

    """
    seq-validation.py -p ${seq_rg_json} -d ${seq}
    """
}
