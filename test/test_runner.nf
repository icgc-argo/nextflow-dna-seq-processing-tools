#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// testing utilities
include './utils'

// processes resources
params.cpus = 1
params.mem = 1024

// test data
test_data_dir = "data"

// common inputs
seq_rg = file('data/seq_rg_output.json')
seq_rg_fq = file('data/seq_rg-fq_output.json')
seq_rg_fq_bz2 = file('data/seq_rg-fq_output.bz2.json')


// Workflow syntax is a new: 
// https://www.nextflow.io/docs/edge/dsl2.html#workflow
// not documented in 'latest' but clearly working as seen below

// Metadata Validation Workflow with test comparison
workflow metadataValidationWF {
    include metadataValidation from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp.json', seq_rg_json_name: 'seq_rg.json')
    include metadataValidation as metadataValidationFQ from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp-fq.json', seq_rg_json_name: 'seq_rg-fq.json')

    exp_tsv = file("${test_data_dir}/experiment.tsv")
    rg_tsv = file("${test_data_dir}/read_group.tsv")
    file_tsv = file("${test_data_dir}/file.tsv")

    exp_tsv_fq = file("${test_data_dir}/experiment-fq.tsv")
    rg_tsv_fq = file("${test_data_dir}/read_group-fq.tsv")
    file_tsv_fq = file("${test_data_dir}/file-fq.tsv")

    metadataValidation(exp_tsv, rg_tsv, file_tsv)
    metadataValidationFQ(exp_tsv_fq, rg_tsv_fq, file_tsv_fq)

    compareMetadataValidationJSON(metadataValidation.out[1].text, seq_rg.text)
    compareMetadataValidationJSON(metadataValidationFQ.out[1].text, seq_rg_fq.text)
}

// Sequence Validation with valid response assertion
workflow sequenceValidationWF {
    include sequenceValidation from '../modules/sequence_validation'
    include sequenceValidation as sequenceValidationFQ from '../modules/sequence_validation'

    sequenceValidation(seq_rg, Channel.fromPath("${test_data_dir}/test_rg_3.*").collect())
    sequenceValidationFQ(seq_rg_fq, Channel.fromPath("${test_data_dir}/seq_rg_fq_test_files/*").collect())

    assertSequenceIsValid(sequenceValidation.out)
    assertSequenceIsValid(sequenceValidationFQ.out)
}

// Preprocess
workflow preprocessWF {
    include seqDataToLaneBam from '../modules/seq_data_to_lane_bam' params(reads_max_discard_fraction: 0.02)
    include seqDataToLaneBam as seqDataToLaneBamFQ from '../modules/seq_data_to_lane_bam'
    include seqDataToLaneBam as seqDataToLaneBamFQBZ2 from '../modules/seq_data_to_lane_bam'

    include extractAlignedBasenameAndBundleType from '../modules/seq_data_to_lane_bam'
    include extractAlignedBasenameAndBundleType as extractAlignedBasenameAndBundleTypeFQ from '../modules/seq_data_to_lane_bam'
    include extractAlignedBasenameAndBundleType as extractAlignedBasenameAndBundleTypeFQBZ2 from '../modules/seq_data_to_lane_bam'

    seqDataToLaneBam(seq_rg, Channel.fromPath("${test_data_dir}/test_rg_3.bam").collect())
    seqDataToLaneBamFQ(seq_rg_fq, Channel.fromPath("${test_data_dir}/seq_rg_fq_test_files/*").collect())
    seqDataToLaneBamFQBZ2(seq_rg_fq_bz2, Channel.fromPath("${test_data_dir}/seq_rg_fq_bz2_test_files/*").collect())

    assertPreprocessIsValid(seqDataToLaneBam.out[1], "172cd780-231b-56ee-815a-f45a29cc3bd9.3.20191011.wgs.grch38")
    assertPreprocessIsValid(seqDataToLaneBamFQ.out[1], "dcde1423-4210-5c9b-a72c-29579a6cfbb3.3.20191011.wgs.grch38")
    assertPreprocessIsValid(seqDataToLaneBamFQBZ2.out[1], "49ae632d-5d56-5637-b2f2-1482ab7c1b35.1.20191011.wgs.grch38")
}


// MAIN WORKFLOW (runs by default)
workflow {
    metadataValidationWF()
    sequenceValidationWF()
    preprocessWF()
}