#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = "0.1.6.0"
params.reads_max_discard_fraction = 0.05

include seqDataToLaneBam from '../process/seq_data_to_lane_bam' params(params)

workflow preprocess {
    get: analysis_id_input_file

    main:
        seqDataToLaneBam(analysis_id_input_file)

    emit:
        unaligned_lanes = seqDataToLaneBam.out.unaligned_lanes.flatMap { it }
}
