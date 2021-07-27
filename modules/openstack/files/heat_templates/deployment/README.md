### 0. Description
This Heat template creates two instances. One with Jenkins CI/CD 
automation server. Another with Gogs Git server.


### 1. Tested environments
This module developed and tested on Debian 10 only.


### 2. Usage
By default in stack are assigned default root password for gogs mariadb database.
But it is good idea to override it during stack build. This command builds full stack,
both Jenkins and Gogs instances.

```
    openstack stack create -t deployment/deployment.yaml --parameter db_password=<password> deployment
```

Also you can build only one required service. Gogs for example.

```
    openstack stack create -t deployment/gogs.yaml \
                           --parameter our_net=10.64.0.0/16 \
                           --parameter network=infrastructure \
                           --parameter subnet=infr-subnet \
                           --parameter db_password=<password> \
                           gogs    
```


*For Jenkins: when instance will be created and cloud-init completes its job*
*'unlock' Jenkins and install desired plugins following theres instructions*
*https://www.jenkins.io/doc/book/installing/#unlocking-jenkins*




#### git example

```
- Ensure that Jenkins Gogs plugin are installed
- Create Jenkins user in Gogs
- Create test repository in Gogs
- In repository create Jenkinsfile with Jenkins pipeline for this repository

    node {
        stage('Build') {
            echo 'Jenkins git test job successfull'
        }
    }


- In Jenkins create Gogs Jenkins user credentials 
  (Manage Jenkins -> Manage Credentials -> Add Credentials (Username with password)
- In Jenkins create new Pipeline with script source from SCM 
  (provide repository URL and credentials)
- In Gogs create webhook to trigger Jenkins pipeline on commit 
  (repository -> setting -> webhooks -> add new webhook)
  Where 'Payload URL' are http://<jenkins_ip>:<jenkins_port>/gogs-webhook/?job=<jenkins_job_name> 
  (for example: http://10.64.40.113:8080/gogs-webhook/?job=git_test_job)
- Make some commit to repository and check if gogs trigger pipeline in Jenkins

```


#### ssh example

```
- In Jenkins create ssh user credentials
  (Manage Jenkins -> Manage Credentials -> Add Credentials (Username with password))
- Create new pipeline
  (New Item -> Pipeline)
- In pipeline section paste this script for example

    node {
        stage('Build') {
            withCredentials([usernamePassword(credentialsId: 'openstack-creds', passwordVariable: 'password', usernameVariable: 'username')]) {
                sh "sshpass -p $password ssh -o 'StrictHostKeyChecking no' $username@10.64.30.100"
            }
        }
    }

- Save, run and check pipeline execution result

```


### 3. Known backgrounds and issues
none


### 4. Used documentation
https://www.jenkins.io/doc/book/installing/
https://gogs.io/docs/installation

