//
// MODULE: Local to the pipeline
//
include { MINIMAP2_ALIGN        } from '../../modules/local/minimap2/align/main'
include { SAMTOOLS_QMAPFILT     } from '../../modules/local/samtools/qmapfilt'

/*
========================================================================================
    RUN ALIGNMENT WORKFLOW
========================================================================================
*/

workflow ALIGNMENT {
   take:
       reads     
    
   main:
    ch_versions = Channel.empty()
    ch_bam = Channel.empty()

    
  // Alignment with the minimap2 module in case no filtering is applied to read length

        MINIMAP2_ALIGN (
        reads,
        params.reference,
        params.bam_format,
        params.cigar_paf_format,
        params.cigar_bam
        )

        MINIMAP2_ALIGN.out.bam
            .set{ ch_bam }

        ch_versions = ch_versions.mix(MINIMAP2_ALIGN.out.versions.first().ifEmpty(null))

        if (!params.skip_qfilt) {
            SAMTOOLS_QMAPFILT (
            MINIMAP2_ALIGN.out.bam,
            params.qscore
            )
            
            SAMTOOLS_QMAPFILT.out.bam
                .set{ ch_bam }
        ch_versions = ch_versions.mix(SAMTOOLS_QMAPFILT.out.versions.first().ifEmpty(null))
        }

   emit:
   bam = ch_bam
   versions = ch_versions
}