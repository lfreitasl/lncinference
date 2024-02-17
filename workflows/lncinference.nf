/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowLncinference.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK                       } from '../subworkflows/local/input_check'
include { QC_FILT                           } from '../subworkflows/local/readsqc'
include { ALIGNMENT                         } from '../subworkflows/local/alignment.nf'
include { STRINGTIE_ASSEMBLY_GTF            } from '../subworkflows/local/stringtie_assembly'
include { CLASSIFICATION_POTENTIAL_CODING   } from '../subworkflows/local/classification_codingpotential.nf'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow LNCINFERENCE {

    ch_versions = Channel.empty()
    ch_bam      = Channel.empty()
    

    // Checking some mandatory parameters
    if (params.skip_alignment && params.input_bams == null) { exit 1, 'A full path to a directory containing BAM files must be provided in input_bams parameter if not aligning your data' }
    if (!params.skip_alignment && (params.input_bams != '' || params.input_bams != "")) { exit 1, 'Choose either aligning or using your own input bams!' }
    
    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    if (!params.skip_alignment || !params.skip_qc){
        INPUT_CHECK (file(params.input))
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    }
    // Subworkflow for quality control

    if (!params.skip_qc) {
        QC_FILT (
        INPUT_CHECK.out.reads,
	    params.cutoff
        )
    
    ch_versions = ch_versions.mix(QC_FILT.out.versions)
    }

    // Subworkflow ALIGNMENT
    if (!params.skip_alignment) {
        if (params.skip_filtering) {
            ALIGNMENT(INPUT_CHECK.out.reads)
        }

        else {
            ALIGNMENT(QC_FILT.out.filt_reads)
        }

        ch_versions = ch_versions.mix(ALIGNMENT.out.versions)
    }

    // Subworkflow stringtie transcript resconstruction
    if (!params.skip_alignment){
        STRINGTIE_ASSEMBLY_GTF(ALIGNMENT.out.bam)
        ch_versions = ch_versions.mix(STRINGTIE_ASSEMBLY_GTF.out.versions)
    }

    if (params.input_bams!='' || params.input_bams!=""){
        Channel.fromPath(params.input_bams).map { path ->
        def meta = [id: path.getBaseName(), type: 'single_end']
        return [meta, path.toString()]
        }.set { ch_bam }

        STRINGTIE_ASSEMBLY_GTF(ch_bam)
        ch_versions = ch_versions.mix(STRINGTIE_ASSEMBLY_GTF.out.versions)
    }


    if (!params.skip_class){
        CLASSIFICATION_POTENTIAL_CODING(STRINGTIE_ASSEMBLY_GTF.out.gtf)
        ch_versions = ch_versions.mix(CLASSIFICATION_POTENTIAL_CODING.out.versions)
    }
    

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowLncinference.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowLncinference.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    if (!params.skip_qc) {
    ch_multiqc_files = ch_multiqc_files.mix(QC_FILT.out.multiqc.ifEmpty([]))
    }
    
    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
