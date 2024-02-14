//
// MODULE: Local to the pipeline
//
include { GFFCOMPARE             } from '../../modules/local/gffcompare/main'
include { GFFREAD                } from '../../modules/local/gffread/main'
include { RNAMINING              } from '../../modules/local/rnamining/main'

/*
========================================================================================
    RUN CLASSIFICATION_POTENTIAL_CODING WORKFLOW
========================================================================================
*/

workflow CLASSIFICATION_POTENTIAL_CODING {
   take:
       gtf     
    
   main:
    ch_versions = Channel.empty()
    ch_assembled_gtfs = Channel.empty()
    ch_merged_gtf = Channel.empty()

    // Classification and potential coding of transcripts in the resulting GTF

    GFFCOMPARE(
        gtf,
        params.refgff
    )

    ch_versions = ch_versions.mix(GFFCOMPARE.out.versions)

    GFFREAD(
        gtf,
        params.reference
    )
    
    ch_versions = ch_versions.mix(GFFREAD.out.versions)

    RNAMINING(
        GFFREAD.out.gtf_fasta
    )

   emit:
   versions = ch_versions
}