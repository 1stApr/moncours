### 0. Description
This module install NFS server and provide interface 
to create export shares from another modules. 


### 1. Tested environments
This module developed and tested on Ubuntu 18.04LTS.


### 2. Usage
In Hiera yaml file provide root folder under which exported folders 
will be created

```
nfs-server:
  root: /exports
```

Install NFS server

```
    # Install
    include nfs::install

    # Delete
    include nfs::delete

```

*Delete manifest only deletes nfs server and exports configuration*
*file. Exported folder it keep in place.*


Export folder from manifest in any other module

```
    nfs::utils::add_export { 'add_volume_export':
      host => '127.0.0.1',
      folder => '/exports/volume',
      owner => 'cinder'
    }
```

### 3. Known backgrounds and issues
Export options are hardcoded in utils.pp manifest


### 4. Used documentation
NFS Ubuntu documentation: https://help.ubuntu.com/lts/serverguide/network-file-system.html
