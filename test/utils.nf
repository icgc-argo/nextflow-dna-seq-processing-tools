#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// groovy goodness
import groovy.json.JsonSlurper
def jsonSlurper = new JsonSlurper()


/*
Metadata Validation Utils
*/
def sortMetadataValidationJSON(jsonMap) {
    if (jsonMap.containsKey("files")) {
        jsonMap.files.sort { a, b -> a.name <=> b.name }
        jsonMap.files.each { it -> sortMetadataValidationJSON(it) }
    }

    if (jsonMap.containsKey("read_groups")) {
        jsonMap.read_groups.sort { a, b -> a.submitter_id <=> b.submitter_id }
    }

    if (jsonMap.containsKey("read_group_submitter_id")) {
        jsonMap.read_group_submitter_id.sort()
    }

    return jsonMap
}

process compareMetadataValidationJSON {
    input:
    val A
    val B

    exec:
        aMap = sortMetadataValidationJSON(jsonSlurper.parseText(A))
        bMap = sortMetadataValidationJSON(jsonSlurper.parseText(B))
        assert aMap.equals(bMap)
}

/*
Sequence Validation Utils
*/
process assertSequenceIsValid {
    input:
    val outputJson

    exec:
        assert jsonSlurper.parseText(outputJson).valid == "valid"
}

/*
Preprocess Utils
*/
process assertPreprocessIsValid {
    input:
    val outputJson
    val expected_basename

    exec:
        assert jsonSlurper.parseText(outputJson).aligned_basename == expected_basename
}