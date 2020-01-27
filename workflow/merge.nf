#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1

// required params w/ default
params.container_version = "0.1.4.1"
params.output_format = ['cram'] // options are ['cram', 'bam']

// optional process inputs
params.markdup = 'OPTIONAL_INPUT'
params.lossy = 'OPTIONAL_INPUT'

include bamMergeSortMarkdup from '../process/bam_merge_sort_markdup' params(params)

workflow merge {
    get: aligned_lane_bams
    get: ref_genome
    get: aligned_basename

    main:
        bamMergeSortMarkdup(aligned_lane_bams, ref_genome, aligned_basename)

    emit:
        merged_aligned_file = bamMergeSortMarkdup.out.merged_aligned_file
}
