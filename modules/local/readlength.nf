process READLENDISTRIBUTION {
        tag "$samples"
        label 'process_single'
        

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://lfreitasl/lalgorithms:latest':
        'docker.io/lfreitasl/lalgorithms:latest' }"
        
        input:
        path samples


        output:
        path '*.txt'        , emit: stats
        path '*.pdf'        , emit: plots


        when:
        task.ext.when == null || task.ext.when

        """
        nextflow-distribution.py $samples
        """
}
