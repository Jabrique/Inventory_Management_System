timestamps {
    podTemplate(
        label: 'podman-inventory-app',
        containers: [
            containerTemplate(
                name: 'podman',
                image: 'quay.io/podman/stable',
                command: 'cat',
                ttyEnabled: true,
                privileged: true
            )
        ],
        volumes: [
            secretVolume(
                secretName: 'harbor-ingress',
                mountPath: '/etc/containers/certs.d/harbor.internskomda.cloud'
            )
        ]
    ) {
        node('podman-inventory-app') {
            stage('Get latest version of code') {
                git branch: 'main', url: 'https://github.com/Jabrique/Inventory_Management_System.git'
            }

            container('podman') {
                stage('Adding an entry to /etc/hosts') {
                    // Adding an entry to /etc/hosts to resolve the hostname harbor.internskomda.cloud
                    sh 'echo "172.16.16.200 harbor.internskomda.cloud" >> /etc/hosts'
                }
                
                stage('Login to Harbor') {
                    withCredentials([usernamePassword(credentialsId: 'Harbor', usernameVariable: 'PODMAN_USER', passwordVariable: 'PODMAN_PASS')]) {
                        sh 'echo ${PODMAN_PASS} | podman login -u ${PODMAN_USER} --password-stdin harbor.internskomda.cloud'
                    }
                }

                stage('build image with Podman') {
                    sh 'podman build --layers --cache-to harbor.internskomda.cloud/inventory-app/cache --cache-from harbor.internskomda.cloud/inventory-app/cache -t inventory-app/inventory-app:v .'
                }

                stage('push image to Harbor using Podman') {
                        // Tag the image
                        sh 'podman tag inventory-app/inventory-app:v harbor.internskomda.cloud/inventory-app/inventory-app:v${BUILD_NUMBER}'
                        
                        // Push the image to Harbor
                        sh 'podman push harbor.internskomda.cloud/inventory-app/inventory-app:v${BUILD_NUMBER}'
                }
            }
            
            stage('update deployment manifest on github') {
                withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        git config user.email "shironimex@gmail.com"
                        git config user.name "Jabrique"
                        sed -i "s#image: harbor.internskomda.cloud/inventory-app/inventory-app:v.*#image: harbor.internskomda.cloud/inventory-app/inventory-app:v${BUILD_NUMBER}#" kubernetes/inventory-app/deployment.yml
                        git add .
                        git commit -m "ci: Update deployment inventory-app image to version ${BUILD_NUMBER}"
                        git push --force https://${GITHUB_TOKEN}@github.com/Jabrique/Inventory_Management_System HEAD:ci/deployment-image
                    '''
                }
            }
        }
    }
}
