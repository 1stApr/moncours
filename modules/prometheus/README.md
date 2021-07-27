### 0. Description
This module install Prometheus monitoring service.
Optionally you can enable alertmanager.


### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS.


### 2. Usage
Provide Prometheus version, metric retention period and IP address
of interface on what prometheus must listen on in Hiera yaml 
configuration file.

Optionally you can install Alertmanager by declaring it in yaml
config and providing desired version number and full path to file 
with openstack credetials. This file will be used by 'autoscaling.sh'
script to issue OpenStack token to make request to OpenStack services.

```
prometheus:
  version: 2.16.0
  retention: 7d
  listen: *public
  alertmanager:               
    version: 0.20.0
    openstack_credentials: /opt/openstack.build/openrc
```

Then include install class to profile

```
    # Install
    include prometheus::install

    # Delete
    include prometheus::delete
```


### 3. Known backgrounds and issues
not found yet


### 4. Used documentation

https://prometheus.io/docs/prometheus/latest/configuration/configuration/
https://medium.com/@pasquier.simon/monitoring-your-openstack-instances-with-prometheus-a7ff4324db6c
https://github.com/syseleven/heat-examples/tree/master/autoscaling/scripts

