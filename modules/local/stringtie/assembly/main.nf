process STRINGTIE_ASSEMBLY {
    tag "$meta.id"
    label 'process_medium'

    // Note: 2.7X indices incompatible with AWS iGenomes.
    conda "bioconda::stringtie=2.1.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/stringtie:2.1.4--h7e0af3c_0' :
        'quay.io/biocontainers/stringtie:2.1.4--h7e0af3c_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.gtf") , emit: stringtie_gtf
    path  "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    

    """
    stringtie \\
        -L \\
        -p $task.cpus \\
        -o ${meta.id}.gtf $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stringtie2: \$(stringtie --version 2>&1)
    END_VERSIONS
    """
}
