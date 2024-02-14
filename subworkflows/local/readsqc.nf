//
// MODULE: Installed directly from nf-core/modules
//

include { FASTQC as RAW_FASTQC  } from '../../modules/nf-core/fastqc/main'
include { FASTQC as FILT_FASTQC } from '../../modules/nf-core/fastqc/main'
include { NANOPLOT as RAW_NANOPLOT  } from '../../modules/nf-core/nanoplot/main'
include { NANOPLOT as FILT_NANOPLOT } from '../../modules/nf-core/nanoplot/main'

//
// MODULE: Local to the pipeline
//
include { NANOFILT              } from '../../modules/local/nanofilt'
include { READLENDISTRIBUTION as RAW_READLENDISTRIBUTION   } from '../../modules/local/readlength'
include { READLENDISTRIBUTION as FILT_READLENDISTRIBUTION   } from '../../modules/local/readlength'

/*
========================================================================================
    RUN QC_FILT WORKFLOW
========================================================================================
*/


workflow QC_FILT {
   take:
       reads
       cutoff       
    
   main:
    ch_versions = Channel.empty()
    ch_multiqc_raw = Channel.empty()
    ch_multiqc_filt = Channel.empty()
    ch_multiqc_all = Channel.empty()
    ch_reads       = reads
   // Running Fastqc on raw reads

    RAW_FASTQC(ch_reads) 

    ch_versions = ch_versions.mix(RAW_FASTQC.out.versions.first().ifEmpty(null))

   // Checking read length distribution on pre-filtered dataset

    RAW_READLENDISTRIBUTION(ch_reads.collect{it[1]}.ifEmpty([]))

   // Running nanoplot on pre-filtered dataset

   RAW_NANOPLOT(ch_reads)

   ch_versions = ch_versions.mix(RAW_NANOPLOT.out.versions.first().ifEmpty(null))

   // Generating a multiqc file for raw reads report

   ch_multiqc_raw = ch_multiqc_raw.mix(RAW_FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
   ch_multiqc_raw = ch_multiqc_raw.mix(RAW_NANOPLOT.out.txt.collect{it[1]}.ifEmpty([]))   
   
   ch_multiqc_all = ch_multiqc_all.mix(ch_multiqc_raw.ifEmpty([]))

   //Putting conditional to whether fun filtering on samples
   if (!params.skip_filtering){
   NANOFILT(reads, cutoff)

   //Running quality check in filtered reads
   FILT_FASTQC(NANOFILT.out.filtreads)

   // Generating custom plot
   FILT_READLENDISTRIBUTION(NANOFILT.out.filtreads.collect{it[1]}.ifEmpty([]))

   // Nanoplot
   FILT_NANOPLOT(NANOFILT.out.filtreads)

   ch_multiqc_filt = ch_multiqc_filt.mix(FILT_FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
   ch_multiqc_filt = ch_multiqc_filt.mix(FILT_NANOPLOT.out.txt.collect{it[1]}.ifEmpty([]))

   ch_multiqc_all = ch_multiqc_all.mix(ch_multiqc_filt.ifEmpty([]))

   // Putting the output of nano filt as new ch_reads
   ch_reads = NANOFILT.out.filtreads
   }

   emit:
   filt_reads = ch_reads
   multiqc = ch_multiqc_all
   versions = ch_versions
}
