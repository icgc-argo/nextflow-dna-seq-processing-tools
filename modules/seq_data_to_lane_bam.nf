#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// groovy goodness
import groovy.json.JsonSlurper
def jsonSlurper = new JsonSlurper()

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = "0.1.5.0"
params.reads_max_discard_fraction = 0.05

process extractAlignedBasenameAndBundleType {
    input:
        tuple lane_bams, val(jsonString)

    output:
        tuple lane_bams, val(result.aligned_basename), val(result.bundle_type)

    exec:
        result = jsonSlurper.parseText(jsonString)
}

process seqDataToLaneBam {

    container "quay.io/icgc-argo/seq-data-to-lane-bam:seq-data-to-lane-bam.${params.container_version}"

    tag "${seq_rg_json} -- ${seq}"

    input:
        tuple path(seq_rg_json), path(seq)

    output:
        tuple path('*.lane.bam'), stdout

    """
    export TMPDIR=\$PWD
    seq-data-to-lane-bam.py -p ${seq_rg_json} -d ${seq} -m ${params.reads_max_discard_fraction}
    """
}

workflow preprocess {
    get: analysis_id_input_file

    main:
        seqDataToLaneBam(analysis_id_input_file)
        extractAlignedBasenameAndBundleType(seqDataToLaneBam.out)

    emit:
        lane_bams = seqDataToLaneBam.out.flatMap { fileBundlePair -> fileBundlePair[0] }
        lane_bams_basename_bundletype = extractAlignedBasenameAndBundleType.out
}
