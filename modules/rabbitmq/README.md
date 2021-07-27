### 0. Description
This module install RabbitMQ message broker on single node.

*note: this module was writen for test enviroment and*
      *passwords provided in plain text*
      *for production environment please use Hiera eyaml*
      *or some secure vault*

*note: this module installs rabbitmq on single node*
      *when node fail all messages will be lost*
      *for production environment*
      *you need setup rabbitmq in cluster manner*


### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS.


### 2. Usage
Provide RabbitMQ user and password in Hiera yaml file

```
  rabbitmq:
    user: root
    password: alex
```

And include install class

```
  # Install
  include rabbitmq::install

  # Delete
  include rabbitmq::delete
```


### 3. Known backgrounds and issues
all fixed now


### 4. Used documentation

Installation: https://www.rabbitmq.com/install-debian.html

Cluster on single machine: http://www.rabbitmq.com/clustering.html#single-machine

Configuration for openstack: https://docs.openstack.org/ha-guide/shared-messaging.html

Config example: https://github.com/rabbitmq/rabbitmq-server/blob/master/docs/rabbitmq.conf.example
