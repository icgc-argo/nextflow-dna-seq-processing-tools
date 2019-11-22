#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// groovy goodness
import groovy.json.JsonSlurper
def jsonSlurper = new JsonSlurper()


process extractBundleType {
    input:
        tuple merged_file, val(jsonString)

    output:
        tuple merged_file, val(bundle_type)

    exec:
        bundle_type = jsonSlurper.parseText(jsonString)['bundle_type']
}

process extractAlignedBasenameAndBundleType {
    input:
        tuple lane_bams, val(jsonString)

    output:
        tuple lane_bams, val(aligned_basename), val(bundle_type)

    exec:
        aligned_basename = jsonSlurper.parseText(jsonString)['aligned_basename']
        bundle_type = jsonSlurper.parseText(jsonString)['bundle_type']
}