### 0. Description

This module install diskimage-builder utility via pip3 install.
For building images with this utility, this module provide
functions in utils.pp manifest. 
This module designed to build images based on Debian and 
Ubuntu Linux distributions.
For suppurt of other Linux distributions this module need some 
additional code.


### 1. Tested environments

This module developed and tested on Ubuntu 18.04LTS.


### 2. Usage

Just include module class to install utility

```
include diskimage_builder::install
```

For usage of image building functions please read actual functions
description in utils.pp.


### 3. Known backgrounds and issues

In this module disk-image-create command called with '--no-tmpfs' property.
This option prevent program to build OS image in memory, altered to use disk
instead. Without this option in systems with low RAM amount couple launches 
of diskimage-builder can consume all available RAM. In systems with high 
RAM amount or on systems without any important production services - remove 
this parameter since it slowdown building process.


### 4. Used documentation

https://docs.openstack.org/diskimage-builder/latest/elements/dhcp-all-interfaces/README.html

