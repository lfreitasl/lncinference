process RNAMINING {
        tag "Predicting_Coding_Potential"
        label 'process_single'
        
        conda "${moduleDir}/environment.yml"
        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://lfreitasl/rnamining:latest':
        'docker.io/lfreitasl/rnamining:latest' }"
        
        input:
        path fasta


        output:
        path '*.txt'        , emit: preds


        when:
        task.ext.when == null || task.ext.when

        script:
        def args  = task.ext.args ? task.ext.args : '-organism_name Mus_musculus -prediction_type coding_prediction'

        """
        python3 /thaisratis_scripts/rnamining.py \\
                -f $fasta \\
                $args \\
                -output_folder ./

        """
}
