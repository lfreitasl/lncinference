//
// MODULE: Local to the pipeline
//
include { STRINGTIE_ASSEMBLY    } from '../../modules/local/stringtie/assembly/main'
include { STRINGTIE_MERGE       } from '../../modules/local/stringtie/merge/main'

/*
========================================================================================
    RUN STRINGTIE_ASSEMBLY_GTF WORKFLOW
========================================================================================
*/

workflow STRINGTIE_ASSEMBLY_GTF {
   take:
       bam     
    
   main:
    ch_versions = Channel.empty()
    ch_assembled_gtfs = Channel.empty()
    ch_merged_gtf = Channel.empty()

    // Assembly of gtf based on alignment

    STRINGTIE_ASSEMBLY (
    bam
    )

    ch_versions = ch_versions.mix(STRINGTIE_ASSEMBLY.out.versions)

    STRINGTIE_ASSEMBLY.out.stringtie_gtf
        .collect { names, paths -> paths }
        .set { ch_assembled_gtfs }

    STRINGTIE_MERGE (
    ch_assembled_gtfs
    )

    ch_versions = ch_versions.mix(STRINGTIE_MERGE.out.versions)

    STRINGTIE_MERGE.out.assembly_gtf
        .set { ch_merged_gtf }

   emit:
   gtf = ch_merged_gtf
   versions = ch_versions
}