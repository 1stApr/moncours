### 0. Description
This module install memcached in single machine.


### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS only.


### 2. Usage
Set address service to bind in Hiera yaml file.

```
memcached:
  bind_address: 127.0.0.1
```


Then to install or delete:

```
  # Install
  include memcached::install

  # Delete
  include memcached::delete
```


### 3. Known backgrounds and issues
Not found yet


### 4. Used documentation

https://docs.openstack.org/mitaka/install-guide-ubuntu/environment-memcached.html