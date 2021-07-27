### 0. Description
This module install MariaDB in single server mode.

*note: this module was writen for test enviroment and*
      *passwords provided in plain text*
      *for production environment please use Hiera eyaml*
      *or some secure vault*

### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS.


### 2. Usage
Provide MariaDB initial parameters in Hiera yaml file

```
    mariadb:
    bind_address: 10.64.10.100
    version: 10.4
    password: alex
```

Then include install class 

```
    # Install
    include mariadb::install

    # Delete
    include mariadb::delete

```


### 3. Known backgrounds and issues

not found yet

### 4. Used documentation

MariaDB documentation: https://mariadb.com/kb/en/library/
