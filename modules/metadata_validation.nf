#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// optional process inputs
params.meta_format = 'OPTIONAL_INPUT'
params.exp_json = 'OPTIONAL_INPUT'

def generateCmdArgsFromParams() {
    cmdArgs = ""

    // process optional inputs
    cmdArgs = params.meta_format != 'OPTIONAL_INPUT' ? "${cmdArgs} -m ${params.meta_format}" : cmdArgs
    cmdArgs = params.exp_json != 'OPTIONAL_INPUT' ? "${cmdArgs} -j ${params.exp_json}" : cmdArgs

    // required args
    cmdArgs = "${cmdArgs} -o ${params.seq_exp_json_name}"
    cmdArgs = "${cmdArgs} -p ${params.seq_rg_json_name}"

    // return trimmed cmd
    return cmdArgs.trim()
}

process metadataValidation {

    container 'quay.io/icgc-argo/metadata-validation:metadata-validation.0.1.2'

    tag "[${exp_tsv.name}-${rg_tsv.name}-${file_tsv.name}] --> ${params.seq_exp_json_name} + ${params.seq_rg_json_name}"

    cpus params.cpus
    memory "${params.mem} MB"

    input:
    file exp_tsv
    file rg_tsv
    file file_tsv

    output:
    file "${params.seq_exp_json_name}"
    file "${params.seq_rg_json_name}"

    """
    metadata-validation.py -e $exp_tsv -r $rg_tsv -f $file_tsv ${generateCmdArgsFromParams()}
    """
}