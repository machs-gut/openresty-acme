pipeline {
    agent {
        label 'jenkins-agent'
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        TZ = 'Asia/Shanghai'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build And Push By Kaniko') {
            steps {
                container('kaniko') {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            set -eu
                            mkdir -p "${WORKSPACE}/.docker"
                            AUTH="$(printf "%s:%s" "${DOCKER_USER}" "${DOCKER_PASS}" | base64 | tr -d '\\n')"
                            printf '{"auths":{"https://index.docker.io/v1/":{"auth":"%s"}}}\n' "${AUTH}" > "${WORKSPACE}/.docker/config.json"
                            export DOCKER_CONFIG="${WORKSPACE}/.docker"

                            SHORT=$(printf '%s' "${GIT_COMMIT:-unknown}" | cut -c1-7)
                            PREFIX="$(printf '%s' "${DOCKER_REGISTRY_PREFIX:-}" | sed 's:/*$::')"
                            TARGET_REPO="${IMAGE_REPO}"
                            if [ -n "${PREFIX}" ]; then
                                TARGET_REPO="${PREFIX}/${IMAGE_REPO}"
                            fi

                            set -- /kaniko/executor \
                                --context "${WORKSPACE}" \
                                --dockerfile "${WORKSPACE}/Dockerfile" \
                                --destination "${TARGET_REPO}:${IMAGE_TAG}" \
                                --destination "${TARGET_REPO}:git-${SHORT}" \
                                --snapshot-mode=redo \
                                --use-new-run

                            if [ "${PUSH_LATEST:-true}" = "true" ]; then
                                set -- "$@" --destination "${TARGET_REPO}:latest"
                            fi

                            "$@"
                        '''
                    }
                }
            }
        }
    }
}
