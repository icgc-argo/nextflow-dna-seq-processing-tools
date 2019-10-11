#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// testing utilities
include './utils'

// processes resources
params.cpus = 1
params.mem = 1024

// common inputs
seq_rg = file('data/seq_rg_output.json')
seq_rg_fq = file('data/seq_rg-fq_output.json')


// Workflow syntax is a new: https://www.nextflow.io/docs/edge/dsl2.html#workflow
// not documented in 'latest' but clearly working as seen below

// Metadata Validation Workflow with test comparison
workflow metadataValidationWF {
    include metadataValidation from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp.json', seq_rg_json_name: 'seq_rg.json')
    include metadataValidation as metadataValidationFQ from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp-fq.json', seq_rg_json_name: 'seq_rg-fq.json')

    exp_tsv = file('data/experiment.tsv')
    rg_tsv = file('data/read_group.tsv')
    file_tsv = file('data/file.tsv')

    exp_tsv_fq = file('data/experiment-fq.tsv')
    rg_tsv_fq = file('data/read_group-fq.tsv')
    file_tsv_fq = file('data/file-fq.tsv')

    metadataValidation(exp_tsv, rg_tsv, file_tsv)
    metadataValidationFQ(exp_tsv_fq, rg_tsv_fq, file_tsv_fq)

    compareMetadataValidationJSON(metadataValidation.out[1].text, seq_rg.text)
    compareMetadataValidationJSON(metadataValidationFQ.out[1].text, seq_rg_fq.text)
}

// Sequence Validation with valid response assertion
workflow sequenceValidationWF {
    include sequenceValidation from '../modules/sequence_validation'
    include sequenceValidation as sequenceValidationFQ from '../modules/sequence_validation'

    sequenceValidation(seq_rg, Channel.fromPath('data/test_rg_3.*').collect())
    sequenceValidationFQ(seq_rg_fq, Channel.fromPath('data/seq_rg_fq_test_files/*').collect())

    assertSequenceIsValid(sequenceValidation.out)
    assertSequenceIsValid(sequenceValidationFQ.out)
}

// Preprocess
workflow preprocessWF {
    include '../modules/preprocess' params(reads_max_discard_fraction: 0.02)

    seqDataToLane(seq_rg, Channel.fromPath('data/test_rg_3.bam').collect())
    extractAlignedBasenameAndBundleType(seqDataToLane.out[1])

    // test output
    // extractAlignedBasenameAndBundleType.out[0].view()
    // extractAlignedBasenameAndBundleType.out[1].view() 
}


// MAIN WORKFLOW (runs by default)
workflow {
    metadataValidationWF()
    sequenceValidationWF()
    preprocessWF()
}