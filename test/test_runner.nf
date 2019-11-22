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

// Preprocess Test (seqDataToLaneBam + extractAlignedBasenameAndBundleType)
workflow preprocessTest {
    include preprocess as testOneBam from '../workflow/preprocess' params(reads_max_discard_fraction: 0.02)
    include preprocess as testMultiple from '../workflow/preprocess'

    testDataOne = Channel.of(
        [file("${test_data_dir}/seq_rg.json"), file("${test_data_dir}/test_rg_3.bam")],
    )

    testDataTwo = Channel.of(
        [file("${test_data_dir}/seq_rg-fq.json"), file("${test_data_dir}/seq_rg_fq_test_files/*").collect()],
        [file("${test_data_dir}/seq_rg-fq.bz2.json"), file("${test_data_dir}/seq_rg_fq_bz2_test_files/*").collect()]
    )

    testOneBam(testDataOne)
    testMultiple(testDataTwo)
    
    if (params.display_output) {
        testOneBam.out.lane_bams_basename_bundletype.view()
        testMultiple.out.lane_bams_basename_bundletype.view()
    }

}

// BWA MEM Aligner
workflow alignTest {
    include bwaMemAligner as testJobLanes from '../process/bwa_mem_aligner.nf'

    bam_lanes = Channel.fromPath("${test_data_dir}/bwa_mem_lanes/*")
    reference_files = Channel.fromPath("${test_data_dir}/reference/*").collect()

    testJobLanes(bam_lanes, reference_files, "grch38-aligned")

    if (params.display_output) {
        testJobLanes.out.view()
    }
}

// Merge
workflow mergeTest {
    include merge from '../workflow/merge.nf' params(markdup: true, lossy: true, output_format: ['bam', 'cram'])

    grch38_lanes = Channel.fromPath("${test_data_dir}/grch38_lanes/*").collect()
    reference_files = Channel.fromPath("${test_data_dir}/reference/*").collect()
    
    merge(grch38_lanes, reference_files, "HCC1143.3.20190726.wgs.grch38")

    if (params.display_output) {
        merge.out.view()
    }
}


// MAIN WORKFLOW (runs by default)
workflow {
    preprocessTest()
    alignTest()
    mergeTest()
}
