#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// testing utilities
include './utils'

// processes resources
params.cpus = 1
params.mem = 1024

// test data
test_data_dir = "data"

// optionally display final process output
params.display_output = false

// Preprocess (seqDataToLaneBam + extractAlignedBasenameAndBundleType)
workflow preprocess {
    include seqDataToLaneBam as testOneBam from '../modules/seq_data_to_lane_bam' params(reads_max_discard_fraction: 0.02)
    include seqDataToLaneBam as testMultiple from '../modules/seq_data_to_lane_bam'

    include extractAlignedBasenameAndBundleType as testExtractOne from '../modules/seq_data_to_lane_bam'
    include extractAlignedBasenameAndBundleType as testExtractTwo from '../modules/seq_data_to_lane_bam'

    testDataOne = Channel.of(
        [file("${test_data_dir}/seq_rg_output.json"), file("${test_data_dir}/test_rg_3.bam")],
    )

    testDataTwo = Channel.of(
        [file("${test_data_dir}/seq_rg-fq_output.json"), file("${test_data_dir}/seq_rg_fq_test_files/*").collect()],
        [file("${test_data_dir}/seq_rg-fq_output.bz2.json"), file("${test_data_dir}/seq_rg_fq_bz2_test_files/*").collect()]
    )

    testOneBam(testDataOne)
    testMultiple(testDataTwo)

    testExtractOne(testOneBam.out)
    testExtractTwo(testMultiple.out)
    
    if (params.display_output) {
        testExtractOne.out.view()
        testExtractTwo.out.view()
    }

}

// BWA MEM Aligner
workflow align {
    include bwaMemAligner as testJobLanes from '../modules/bwa_mem_aligner.nf'

    bam_lanes = Channel.fromPath("${test_data_dir}/bwa_mem_lanes/*")
    reference_files = Channel.fromPath("${test_data_dir}/reference/*").collect()

    testJobLanes(bam_lanes, reference_files, "grch38-aligned")

    if (params.display_output) {
        testJobLanes.out.view()
    }
}

// Merge
workflow merge {
    include bamMergeSortMarkdup as testMMJob from '../modules/bam_merge_sort_markdup.nf' params(markdup: true, lossy: true, output_format: ['bam', 'cram'])
    include extractBundleType as testEBTJob from '../modules/bam_merge_sort_markdup.nf'

    grch38_lanes = Channel.fromPath("${test_data_dir}/grch38_lanes/*").collect()
    reference_files = Channel.fromPath("${test_data_dir}/reference/*").collect()
    
    testMMJob(grch38_lanes, reference_files, "HCC1143.3.20190726.wgs.grch38")
    testEBTJob(testMMJob.out)

    if (params.display_output) {
        testEBTJob.out.view()
    }
}


// MAIN WORKFLOW (runs by default)
workflow {
    preprocess()
    align()
    merge()
}
