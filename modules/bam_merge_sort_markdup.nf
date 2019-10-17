#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// groovy goodness
import groovy.json.JsonSlurper
def jsonSlurper = new JsonSlurper()

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = "0.1.3"
params.output_format = ['cram'] // options are ['cram', 'bam']

// optional process inputs
params.markdup = 'OPTIONAL_INPUT'
params.lossy = 'OPTIONAL_INPUT'

def generateCmdArgsFromParams() {
    cmdArgs = ""

    // process optional inputs
    cmdArgs = params.markdup != 'OPTIONAL_INPUT' ? "${cmdArgs} -d" : cmdArgs
    cmdArgs = params.lossy != 'OPTIONAL_INPUT' ? "${cmdArgs} -l" : cmdArgs

    // required args
    cmdArgs = "$cmdArgs -o ${params.output_format.join(' ')}"
    cmdArgs = "$cmdArgs -n $params.cpus"

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

    container "quay.io/icgc-argo/bam-merge-sort-markdup:bam-merge-sort-markdup.${params.container_version}"

    tag "${aligned_lane_bams} -- ${aligned_basename}"

    cpus params.cpus
    memory "${params.mem} MB"

    input:
    file aligned_lane_bams
    file ref_genome
    val aligned_basename

    output:
    file "${aligned_basename}.*"
    stdout()

    script:
    ref = ref_genome.collectEntries { [(it.getExtension()) : it] }
    """
    bam-merge-sort-markdup.py -i $aligned_lane_bams -r $ref.fa -b $aligned_basename -n $params.cpus ${generateCmdArgsFromParams()}
    """
}
