### 0. Description
This module install haproxy in single machine.
Does not perfom any configuration and ensures 
that haproxy system service is disabled and stopped.

OpenStack neutron uses haproxy for dhcp service HA. 
But it run it by themselfs and don't need haproxy 
to be configured and runned as system service.


### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS only.


### 2. Usage
Install or delete:

```
  # Install
  include haproxy::install

  # Delete
  include haproxy::delete
```


### 3. Known backgrounds and issues
Not found yet


### 4. Used documentation
None