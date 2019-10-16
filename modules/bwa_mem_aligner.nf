#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

process bwaMemAligner {
    container 'quay.io/icgc-argo/bwa-mem-aligner:bwa-mem-aligner.0.1.2'

    tag "${input_bam}"

    cpus params.cpus
    memory "${params.mem} MB"

    input:
    file input_bam
    file ref_genome
    val aligned_lane_prefix

    output:
    file "${aligned_lane_prefix}.${input_bam.baseName}"

    script:
    ref = ref_genome.collectEntries { [(it.getExtension()) : it] }
    """
    bwa-mem-aligner.py -i $input_bam -r $ref.fa -n $params.cpus -o $aligned_lane_prefix
    """
}