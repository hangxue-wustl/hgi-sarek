process GATK4_LEARNREADORIENTATIONMODEL {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::gatk4=4.6.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://broadinstitute/gatk:4.6.0.0':
        'biocontainers/gatk:4.6.0.0' }"

    input:
    tuple val(meta), path(f1r2)

    output:
    tuple val(meta), path("*.tar.gz"), emit: artifactprior
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_list = f1r2.collect{"--input $it"}.join(' ')

    def avail_mem = 3072
    if (!task.memory) {
        log.info '[GATK LearnReadOrientationModel] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }
    """
    gatk --java-options "-Xmx${avail_mem}M -XX:-UsePerfData -XX:+UseSerialGC" \\
        LearnReadOrientationModel \\
        $input_list \\
        --output ${prefix}.tar.gz \\
        --tmp-dir . \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
