#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus_metadata_validation = 1
params.mem_metadata_validation = 1024

// optional process inputs
params.meta_format = 'OPTIONAL_INPUT'
params.exp_json = 'OPTIONAL_INPUT'

def generateCmdArgs(seq_exp_json_name, seq_rg_json_name) {
    cmdArgs = ""

    // process optional inputs
    cmdArgs = params.meta_format != 'OPTIONAL_INPUT' ? "${cmdArgs} -m ${meta_format}" : cmdArgs
    cmdArgs = params.exp_json != 'OPTIONAL_INPUT' ? "${cmdArgs} -j ${exp_json}" : cmdArgs

    // required args
    cmdArgs = "${cmdArgs} -o ${seq_exp_json_name}"
    cmdArgs = "${cmdArgs} -p ${seq_rg_json_name}"

    // return trimmed cmd
    return cmdArgs.trim()
}

process metadataValidation {

    container 'quay.io/icgc-argo/metadata-validation:metadata-validation.0.1.2'

    tag "TODO: INSERT TAG HERE"

    cpus params.cpus_metadata_validation
    memory "${params.mem_metadata_validation} MB"

    input:
    file exp_tsv
    file rg_tsv
    file file_tsv
    val seq_exp_json_name
    val seq_rg_json_name

    output:
    file "${seq_exp_json_name}"
    file "${seq_rg_json_name}"

    """
    metadata-validation.py -e $exp_tsv -r $rg_tsv -f $file_tsv ${generateCmdArgs(seq_exp_json_name, seq_rg_json_name)}
    """
}