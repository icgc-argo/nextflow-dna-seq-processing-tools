#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// metadataValidation inputs
exp_tsv = file('data/experiment.tsv')
rg_tsv = file('data/read_group.tsv')
file_tsv = file('data/file.tsv')
exp_tsv_fq = file('data/experiment-fq.tsv')
rg_tsv_fq = file('data/read_group-fq.tsv')
file_tsv_fq = file('data/file-fq.tsv')
seq_rg = file('data/seq_rg_output.json')
seq_rg_fq = file('data/seq_rg-fq_output.json')

// module imports
include metadataValidation from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp.json', seq_rg_json_name: 'seq_rg.json')
include metadataValidation as metadataValidationFq from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp-fq.json', seq_rg_json_name: 'seq_rg-fq.json')

process compareJSON {
    container 'cfmanteiga/alpine-bash-curl-jq'
    
    input:
    file A
    file B
    
    """
    jq --argfile a ${A} --argfile b ${B} -n \
    'def post_recurse(f): def r: (f | select(. != null) | r), .; r; def post_recurse: post_recurse(.[]?); \
    (\$a | (post_recurse | arrays) |= sort) as \$a | (\$b | (post_recurse | arrays) |= sort) as \$b | \
    if \$a == \$b then true else error("json does not match") end'
    """
}

// Workflow syntax is a new: https://www.nextflow.io/docs/edge/dsl2.html#workflow
// not documented in 'latest' but clearly working as seen below

// metadataValidation Workflow with test compare
workflow metadataValidationWF {
    metadataValidation(exp_tsv, rg_tsv, file_tsv)
    metadataValidationFq(exp_tsv_fq, rg_tsv_fq, file_tsv_fq)

    compareJSON(metadataValidation.out[1], seq_rg)
    compareJSON(metadataValidationFq.out[1], seq_rg_fq)
}

// main workflow
workflow {
    metadataValidationWF()
}