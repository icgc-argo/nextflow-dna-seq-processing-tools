# DNA Sequencing Reads Processing (Nextflow)
_Nextflow implementation of https://github.com/icgc-argo/dna-seq-processing-tools_

This repository intends to provide a Nextflow implementation of the Common Workflow Language (CWL) tools defined in the above referenced repository.

Using Nextflow's experimental DSL2, the modules defined in the repo can be imported and used as part of a larger workflow (or independently).


## Requirements

- Nextflow: [v19.10.0](https://github.com/nextflow-io/nextflow/releases/tag/v19.10.0)
- Docker

## Testing

The tests folder contains a `test_runner.wf` workflow that imports each module and independently tests it. To run the tests just `cd` into the tests directory and run the following command:

`nextflow run test_runner.wf`

This will kick off a complete test of all the modules in this repo. All test data is contained within `test/data`. There a few helper processes defined in the `utils.nf` workflow but they are strictly for testing purposed and not needed/intended for use outside of that scope.
