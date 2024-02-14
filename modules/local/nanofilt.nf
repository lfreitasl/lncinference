process NANOFILT {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::nanofilt=2.8.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://themariya/nanofilt:latest':
        'docker.io/themariya/nanofilt:latest' }"

    input:
    tuple val(meta), path(reads)
    val cutoff

    output:
    tuple val(meta), path("*.fastq.gz"), emit: filtreads
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
        gunzip \\
        -c $reads \\
        | NanoFilt \\
        --maxlength $cutoff \\
        | gzip > ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanofilt: \$(NanoFilt -v |& sed '1!d ; s/NanoFilt //')
    END_VERSIONS
    """

}
