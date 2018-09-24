package org.pmiops.workbench.tooling

import groovy.util.logging.Slf4j
import io.swagger.codegen.DefaultGenerator
import io.swagger.codegen.config.CodegenConfigurator
import org.apache.commons.lang3.tuple.ImmutableTriple
import org.gradle.api.DefaultTask
import org.gradle.api.tasks.TaskAction

@SuppressWarnings(["unused"])
@Slf4j
class GenerateAPIClientsTask extends DefaultTask {

    String rootProjDir
    String targetFolder
    String templateDir
    Map<String, Object> defaultProps
    List<ImmutableTriple<String, String, Map<String, Object>>> fileConfigs

    @TaskAction
    void defaultAction() {
        fileConfigs.each { configMap ->
            String apiFile = configMap.left
            String lang = configMap.middle
            Map additionalProps = configMap.right
            CodegenConfigurator config = new CodegenConfigurator()
            config.setInputSpec("file:///$rootProjDir/$apiFile")
            config.setOutputDir(rootProjDir)
            config.setTemplateDir("$rootProjDir/$templateDir")
            config.setLang(lang)
            config.setAdditionalProperties(defaultProps + additionalProps)
            new DefaultGenerator().opts(config.toClientOptInput()).generate()
        }
    }

}
