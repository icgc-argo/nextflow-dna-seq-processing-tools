#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// process inputs
exp_tsv = file('data/experiment.tsv')
rg_tsv = file('data/read_group.tsv')
file_tsv = file('data/file.tsv')

exp_tsv_fq = file('data/experiment-fq.tsv')
rg_tsv_fq = file('data/read_group-fq.tsv')
file_tsv_fq = file('data/file-fq.tsv')

// modules
include metadataValidation from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp.json', seq_rg_json_name: 'seq_rg.json')
include metadataValidation as metadataValidationFq from '../modules/metadata_validation' params(seq_exp_json_name: 'seq_exp-fq.json', seq_rg_json_name: 'seq_rg-fq.json')

// run
metadataValidation(exp_tsv, rg_tsv, file_tsv)
metadataValidationFq(exp_tsv_fq, rg_tsv_fq, file_tsv_fq)