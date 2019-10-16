#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// groovy goodness
import groovy.json.JsonSlurper
def jsonSlurper = new JsonSlurper()

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.lossy = false

// optional process inputs
markdup = 'OPTIONAL_INPUT'
output_format = 'OPTIONAL_INPUT'

def generateCmdArgsFromParams() {
    cmdArgs = ""

    // process optional inputs
    cmdArgs = params.markdup != 'OPTIONAL_INPUT' ? "${cmdArgs} -d ${params.markdup}" : cmdArgs
    cmdArgs = params.output_format != 'OPTIONAL_INPUT' ? "${cmdArgs} -o ${params.output_format}" : cmdArgs

    // return trimmed cmd
    return cmdArgs.trim()
}

process extractBundleType {
    input:
    val jsonString

    output:
    val result

    exec:
        result = jsonSlurper.parseText(jsonString).bundle_type
}

process bamMergeSortMarkdup {

    container 'quay.io/icgc-argo/bam-merge-sort-markdup:bam-merge-sort-markdup.0.1.3'

    tag "${aligned_lane_bams} -- ${aligned_basename}"

    input:
    file aligned_lane_bams
    file ref_genome
    val aligned_basename

    output:
    file aligned_bam optional true
    file aligned_duplicate_metrics optional true
    aligned_cram optional true
    stdout()

    """
    metadata-validation.py -i $aligned_lane_bams -r $ref_genome -b $aligned_basename -n $params.cpus -l $params.lossy ${generateCmdArgsFromParams()}
    """
}
