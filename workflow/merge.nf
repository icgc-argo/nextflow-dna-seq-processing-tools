#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = "0.1.4"
params.output_format = ['cram'] // options are ['cram', 'bam']

// optional process inputs
params.markdup = 'OPTIONAL_INPUT'
params.lossy = 'OPTIONAL_INPUT'

include bamMergeSortMarkdup from '../process/bam_merge_sort_markdup' params(params)
include extractBundleType from '../process/utils'

workflow merge {
    get: aligned_lane_bams
    get: ref_genome
    get: aligned_basename

    main:
        bamMergeSortMarkdup(aligned_lane_bams, ref_genome, aligned_basename)
        extractBundleType(bamMergeSortMarkdup.out)

    emit:
        merged_bam = bamMergeSortMarkdup.out.flatMap { fileBundlePair -> fileBundlePair[0] }
        merged_bam_bundletype = extractBundleType.out
}