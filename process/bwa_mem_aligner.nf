#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1

// required params w/ default
params.container_version = "0.1.2"

process bwaMemAligner {
    container "quay.io/icgc-argo/bwa-mem-aligner:bwa-mem-aligner.${params.container_version}"

    label "align"
    tag "${input_file.size()}"

    cpus params.cpus
    memory "${params.mem} GB"

    input:
        path input_file
        path ref_genome
        val aligned_lane_prefix

    output:
        path "${aligned_lane_prefix}.${input_file.baseName}.*", emit: aligned_file

    script:
        ref = ref_genome.collectEntries { [(it.getExtension()) : it] }
        """
        bwa-mem-aligner.py -i $input_file -r $ref.gz -n $params.cpus -o $aligned_lane_prefix
        """
}
