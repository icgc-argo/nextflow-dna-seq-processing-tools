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
seq_rg = path('data/seq_rg_output.json')
seq_rg_fq = path('data/seq_rg-fq_output.json')
seq_rg_fq_bz2 = path('data/seq_rg-fq_output.bz2.json')


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

// BWA MEM Aligner
workflow bwaMemAlignerWF {
    include bwaMemAligner as testJobLanes from '../modules/bwa_mem_aligner.nf'

    testJobLanes(Channel.fromPath("${test_data_dir}/bwa_mem_lanes/*"), Channel.fromPath("${test_data_dir}/reference/*").collect(), "grch38-aligned")
}

// Merge
workflow merge {
    include bamMergeSortMarkdup as testMMJob from '../modules/bam_merge_sort_markdup.nf' params(markdup: true, lossy: true, output_format: ['bam', 'cram'])
    include extractBundleType as testEBTJob from '../modules/bam_merge_sort_markdup.nf'

    testMMJob(Channel.fromPath("${test_data_dir}/grch38_lanes/*").collect(), Channel.fromPath("${test_data_dir}/reference/*").collect(), "HCC1143.3.20190726.wgs.grch38")
    testEBTJob(testMMJob.out[1])
}


// MAIN WORKFLOW (runs by default)
workflow {
    preprocessWF()
    mergeMarkdupWF()
    bwaMemAlignerWF()
}
