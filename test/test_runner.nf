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
    include metadataValidation as testMVJobBam from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp.json', seq_rg_json_name: 'seq_rg.json')
    include metadataValidation as testMVJobFQ from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp-fq.json', seq_rg_json_name: 'seq_rg-fq.json')

    exp_tsv = file("${test_data_dir}/experiment.tsv")
    rg_tsv = file("${test_data_dir}/read_group.tsv")
    file_tsv = file("${test_data_dir}/file.tsv")

    exp_tsv_fq = file("${test_data_dir}/experiment-fq.tsv")
    rg_tsv_fq = file("${test_data_dir}/read_group-fq.tsv")
    file_tsv_fq = file("${test_data_dir}/file-fq.tsv")

    testMVJobBam(exp_tsv, rg_tsv, file_tsv)
    testMVJobFQ(exp_tsv_fq, rg_tsv_fq, file_tsv_fq)

    compareMetadataValidationJSON(testMVJobBam.out[1].text, seq_rg.text)
    compareMetadataValidationJSON(testMVJobFQ.out[1].text, seq_rg_fq.text)
}

// Sequence Validation with valid response assertion
workflow sequenceValidationWF {
    include sequenceValidation as testSVJobBam from '../modules/sequence_validation'
    include sequenceValidation as testSVJobFQ from '../modules/sequence_validation'

    testSVJobBam(seq_rg, Channel.fromPath("${test_data_dir}/test_rg_3.*").collect())
    testSVJobFQ(seq_rg_fq, Channel.fromPath("${test_data_dir}/seq_rg_fq_test_files/*").collect())

    assertSequenceIsValid(testSVJobBam.out)
    assertSequenceIsValid(testSVJobFQ.out)
}

// Preprocess (seqDataToLaneBam + extractAlignedBasenameAndBundleType)
workflow preprocessWF {
    include seqDataToLaneBam as testOneBam from '../modules/seq_data_to_lane_bam' params(reads_max_discard_fraction: 0.02)
    include seqDataToLaneBam as test_FQ_BamDir from '../modules/seq_data_to_lane_bam'
    include seqDataToLaneBam as test_FQ_BZ_BamDir from '../modules/seq_data_to_lane_bam'

    include extractAlignedBasenameAndBundleType as testExtractOne from '../modules/seq_data_to_lane_bam'
    include extractAlignedBasenameAndBundleType as testExtractTwo from '../modules/seq_data_to_lane_bam'
    include extractAlignedBasenameAndBundleType as testExtractThree from '../modules/seq_data_to_lane_bam'

    testOneBam(seq_rg, Channel.fromPath("${test_data_dir}/test_rg_3.bam").collect())
    test_FQ_BamDir(seq_rg_fq, Channel.fromPath("${test_data_dir}/seq_rg_fq_test_files/*").collect())
    test_FQ_BZ_BamDir(seq_rg_fq_bz2, Channel.fromPath("${test_data_dir}/seq_rg_fq_bz2_test_files/*").collect())

    testExtractOne(testOneBam.out[1])
    testExtractTwo(test_FQ_BamDir.out[1])
    testExtractThree(test_FQ_BZ_BamDir.out[1])
}

// Merge Markdup
workflow mergeMarkdupWF {
    include bamMergeSortMarkdup as testMMJob from '../modules/bam_merge_sort_markdup.nf' params(markdup: true, lossy: true, output_format: ['bam', 'cram'])
    include extractBundleType as testEBTJob from '../modules/bam_merge_sort_markdup.nf'

    testMMJob(Channel.fromPath("${test_data_dir}/grch38_lanes/*").collect(), Channel.fromPath("${test_data_dir}/reference/*").collect(), "HCC1143.3.20190726.wgs.grch38")
    testEBTJob(testMMJob.out[1])
}

// BWA MEM Aligner
workflow bwaMemAlignerWF {
    include bwaMemAligner as testJobLanes from '../modules/bwa_mem_aligner.nf'

    testJobLanes(Channel.fromPath("${test_data_dir}/bwa_mem_lanes/*"), Channel.fromPath("${test_data_dir}/reference/*").collect(), "grch38-aligned")
}


// MAIN WORKFLOW (runs by default)
workflow {
    metadataValidationWF()
    sequenceValidationWF()
    preprocessWF()
    mergeMarkdupWF()
    bwaMemAlignerWF()
}
