#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// process inputs
exp_tsv = file('input/experiment.tsv')
rg_tsv = file('input/read_group.tsv')
file_tsv = file('input/file.tsv')

exp_tsv_fq = file('input/experiment-fq.tsv')
rg_tsv_fq = file('input/read_group-fq.tsv')
file_tsv_fq = file('input/file-fq.tsv')

// modules
include metadataValidation from '../modules/metadata_validation'
include metadataValidation as foo from '../modules/metadata_validation'

// run
metadataValidation(exp_tsv, rg_tsv, file_tsv, 'seq_exp.json', 'seq_rg.json')

foo(exp_tsv_fq, rg_tsv_fq, file_tsv_fq, 'seq_exp-fq.json', 'seq_rg-fq.json')