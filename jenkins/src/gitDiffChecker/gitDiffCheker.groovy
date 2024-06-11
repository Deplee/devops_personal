/* groovylint-disable DuplicateListLiteral, DuplicateMapLiteral */
@Library('RootJenkinsLibs') import tst.tst.jenkins.lib.libname


properties([
    gitLabConnection(
        gitLabConnection: 'GitLab',
        jobCredentialId: ''
    ),
    durabilityHint('MAX_SURVIVABILITY'),
    buildDiscarder(
        logRotator(
            artifactDaysToKeepStr: '',
            artifactNumToKeepStr: '',
            daysToKeepStr: '',
            numToKeepStr: '30'
        )
    ),
    parameters([
        gitParameter(
            branch: 'main',
            branchFilter: 'origin/(.*)',
            defaultValue: '',
            listSize: '5',
            name: 'RC_BRANCH',
            quickFilterEnabled: true,
            requiredParameter: true,
            selectedValue: 'DEFAULT',
            sortMode: 'NONE',
            tagFilter: '*',
            type: 'GitParameterDefinition',
            useRepository: '.*backend.git'),
    [
        $class      : 'WHideParameterDefinition',
        defaultValue: 'main',
        name        : 'MAIN_BRANCH'
    ]
    ])
])

REPO_URL = 'git@gitlab.lcgs.ru:name/repo.git'
manager.addShortText(text = "${RC_BRANCH}, ${MAIN_BRANCH}", background = 'white', border = 'black', borderColor = '0px', color = 'white')

timestamps {
    ansiColor('xterm') {
        node('node-label') {
            stage('Clone repositories') {
                println('BEGIN SECTION Clone repositories')
                println('----> Clone Backend')
                git branch: env.RC_BRANCH, credentialsId: 'gitlab_gituser', url: REPO_URL
                dir('backend') {
                    sh '''#!/bin/bash
                    IFS="|"
                    APP=('app_part_name-1' 'app_part_name-2' 'app_part_name-3')
                    DF=$(git diff --name-only $RC_BRANCH $MAIN_BRANCH | egrep -w "${APP[*]}" -o |  sort -u)
                    echo -e "=====DIFFERENCE BETWEEN $RC_BRANCH and $MAIN_BRANCH"
                    echo -e "$DF"
                    '''
                }
            }
        }
    }
}
