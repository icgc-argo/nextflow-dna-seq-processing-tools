#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// common inputs
seq_rg = file('data/seq_rg_output.json')
seq_rg_fq = file('data/seq_rg-fq_output.json')

// testing utility processes
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

// Metadata Validation Workflow with test compare
workflow metadataValidationWF {
    include metadataValidation from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp.json', seq_rg_json_name: 'seq_rg.json')

    exp_tsv = file('data/experiment.tsv')
    rg_tsv = file('data/read_group.tsv')
    file_tsv = file('data/file.tsv')

    metadataValidation(exp_tsv, rg_tsv, file_tsv)
    compareJSON(metadataValidation.out[1], seq_rg)
}

workflow metadataValidationFQWF {
    include metadataValidation as metadataValidationFQ from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp-fq.json', seq_rg_json_name: 'seq_rg-fq.json')
    
    exp_tsv_fq = file('data/experiment-fq.tsv')
    rg_tsv_fq = file('data/read_group-fq.tsv')
    file_tsv_fq = file('data/file-fq.tsv')

    metadataValidationFQ(exp_tsv_fq, rg_tsv_fq, file_tsv_fq)
    compareJSON(metadataValidationFQ.out[1], seq_rg_fq)
}

// Sequence Validation 
workflow sequenceValidationWF {
    include sequenceValidation from '../modules/sequence_validation'
    include sequenceValidation as sequenceValidationFQ from '../modules/sequence_validation'

    sequenceValidation(seq_rg, Channel.fromPath('data/test_rg_3.*').collect())
    sequenceValidationFQ(seq_rg_fq, Channel.fromPath('data/seq_rg_fq_test_files/*').collect())
}

workflow preprocessWF {
    include '../modules/preprocess' params(reads_max_discard_fraction: 0.02)

    seqDataToLane(seq_rg, Channel.fromPath('data/test_rg_3.bam').collect())
    extractAlignedBasenameAndBundleType(seqDataToLane.out[1])

    // test output
    extractAlignedBasenameAndBundleType.out[0].view()
    extractAlignedBasenameAndBundleType.out[1].view() 
}

// main workflow (runs by default)
workflow {
    metadataValidationWF()
    sequenceValidationWF()
    preprocessWF()
}