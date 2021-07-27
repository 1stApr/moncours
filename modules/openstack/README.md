### 0. Description

This module install OpenStack services in single machine.

Services covered by this module:

* Keystone    - Identity Service
* Neutron     - Network
* Nova        - Computing
* Placement   - Placement
* Glance      - Image Service
* Cinder      - Block Storage
* Horizon     - Dashboard
* Heat        - Orchestration 
* Murano      - Application Catalog

* Celiometer  - Telemetry Data Collection
* Aodh        - Alarming Service
* Gnocchi     - Time Series Database


**Neutron**

Neutron network is a complicated topic. Before you begin please read 
official Neutron documentation. About provider network via bridge interface
also read [NETWORK_BRIDGE.md](NETWORK_BRIDGE.md). About provider network via 
trunk with Vlan network isolation read [NETWORK_VLANS.md](NETWORK_VLANS.md)

**Nova**

Nova service propose cells mechanism for compute resources sharding and isolation.
This deployment uses this mechanism and assign compute resources to Cell1.
For more information read Nova official documentation and [NOVA_CELLS.md](NOVA_CELLS.md)
readme.

**Glance**

Some OS images provided by Linux distribution developers are completely 
compatible with OpenStack and some are not. For example Debian distribution
can be used with OpenStack without any changes. So Debian we download
from distribution repository and import to Glance as is. In the same time
by default in Ubuntu distribution 'cloud-init' datasource parameter sets to 'none'.
So default Ubuntu image can't get OpenStack instance metadata not from 
'config drive', not from Nova metadata service. Thats why we are build 
our custom Ubuntu minimal image with diskimage-builder utility.

*note: buiding OS image from scratch requires a lot of operations*
*and package downloads. So this process are time consuming and can*
*lasted up to 30 min depending on system resources and internet access speed.*

**Murano**

Murano agent can be installed by cloud-init script. Murano service injects all
nessary user data for it. But recommended way is to build OS images with
preinstalled murano-agent. And use this images separately from other glance images.
Thats why in this deployment Murano OS images are builded with diskimage-builder
utility with preinstalled murano-agent.

*note: buiding OS image from scratch requires a lot of operations*
*and package downloads. So this process are time consuming and can*
*lasted up to 30 min depending on system resources and internet access speed.*

*note: limited murano functions in this deployment.*
*Murano server use rabbitmq to communicate with murano-agent inside virtual machine.*
*Configuration parameters for murano-agent it takes from murano.conf [rabbitmq] section.*
*But since in this setup for management network are used localhost (127.0.0.1).*
*Murano-agent can not communicate with OpenStack rabbitmq server.*
*So murano-agent can not deploy pure murano applications.*
*It can be used only for deployment of Heat templates.*
*Look at [CirrOS example](files/murano_apps/cirros)*

**Telemetry**

This deployment has manifests to install OpenStack Telemetry services - Ceilometer,
Aodh, Gnocchi. There services are working well, but there are no any documentation
how to use it. So instead of using OpenStack Telemetry services for monitoring and
alarming this deployment used Prometheus instead. For more information please read
[PROMETHEUS_AUTOSCALING.md](PROMETHEUS_AUTOSCALING.md) readme.


### 1. Tested environments

This module developed and tested on Ubuntu 18.04LTS.


### 2. Usage

Provide general and service specific configuration information
in Hiera yaml file.

```
openstack:
  # Release to install. 
  # Options 'master' (currently 'ussuri' release) and 'stable/train'
  # Other releases not tested                 
  release: stable/train

  # Cloud region
  region: RegionUA

  # Cloud Organization
  domain: Organisation

  # Project name 
  project: Cloud
  
  # Folder where Git clone OpenStack repositories and perform buid tasks
  root: /home/alex/openstack.build

  # Full path to file with OpenStack credentials 
  credentials: /home/alex/openstack.build/openrc

  # Ip address of management network interface
  # In All-in-One setup it is loopback interface
  management_ip: 127.0.0.1

  # Ip address of public network interface
  public_ip: 10.64.30.100

  # Administrator and services password
  password: password

  # Secret for secure communication between Nova and Neutron services
  # Generated with command:
  #
  #   openssl rand -hex 10
  #
  metadata_secret: d9e496c321d357fa6b11               
  
  # Full path to log files root folder
  # Log files will be stored under '$logs_dir/$service' folder
  # For example: /var/log/openstack/murano/
  logs_dir: '/var/log/openstack'

  # Full path for services working root folder
  # Work files will be stored under '$service_dir/$service' folder
  # For example: /var/lib/openstack/murano/
  service_dir: '/var/lib/openstack'
  
  # Configuration options for log rotate service
  logrotate:
    # How often to rotate logs
    threshold: daily
    # How many logs to keep
    keep: 1                                           

  # List of services to install
  # Puppet install services in loop one by one from this list
  # If you don't want to install particular service 
  # just comment it this file
  services:
    
    # Install Identity Service
    keystone:

    # Install Image Service
    glance: 
      # Images list to download or build and import in Glance catalog
      images:
        cirros-0.4.0-x86_64:
          link: http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
          type: cirros.demo

        # Configuration to build image with diskimage-builder
        # Image name 
        ubuntu-18.04-minimal-amd64:
          # Distribution name
          distribution: ubuntu
          # Release name
          release: bionic
          # Image type
          type: linux
          # Minimum virtual machine disk size in GB required by this image
          # for successfull installation
          min_disk: 4          

        # Configuration to download prebuilded image from distribution repository
        # Image name
        debian-10.3.0-amd64:
          # Download URL
          link: https://cdimage.debian.org/cdimage/openstack/current/debian-10.3.0-openstack-amd64.qcow2
          # Image type 
          type: linux
          # Minimum virtual machine disk size in GB required by this image
          # for successfull installation
          min_disk: 4
    
    # Install Placement Service
    placement:

    # Install Block Storage service
    cinder: 
      # Configure NFS Server as backend for Block Storage service
      nfs:
        # Full path for catalog exported by NFS server for virtual machines
        volume: /exports/instances
        # Full path for catalog exported by NFS server for backup purpose
        backup: /exports/backup

    # Install Networking Service
    neutron:
      # List of linux kernel modules required by Neutron services
      kernel_modules:
        - bridge
        - br_netfilter
      
      # Provider network configuration
      # About network configuration options covered by this module 
      # please read NETWORK_BRIDGE.md, NETWORK_VLANS.md and 
      # OpenStack Neutron documentation  
      provider:
        # Provider network
        range: 10.64.30.0/24
        # Default gateway
        gateway: 10.64.30.1
        # Default DNS server
        dns: 8.8.8.8
        # Range of addresses safe to lease via DHCP 
        # Range first address
        pool_start: 10.64.30.200
        # Range end
        pool_end: 10.64.30.254

    # Install Compute Service
    nova:
      # Hypervisor
      # any other hypervisors doesnt supported by this module
      hypervisor: kvm     
      # Cpu mode
      # Available options are none, host-model, host-passthrough
      # In host-passthrough mode nova tells kvm to expose cpu to instance
      # without any modifications. This mode delivers the best perfomance.
      # But live-migration in this mode are available only between hosts 
      # with the same cpu model, microcode versions and sometimes the same 
      # kernel versions. Use this mode only if you have very homogenius environment
      # or you deside not to use live migration at all.
      cpu_mode: host-passthrough                                
      # Client name for instances console access
      # any other options doesnt supported by this module
      console: spice-html5                                

    # Install Application Catalog Service
    murano: 
      images:
        # Configuration to build image with diskimage-builder
        # Image name 
        ubuntu-18.04-minimal-amd64:
          # Distribution name
          distribution: ubuntu
          # Release name
          release: bionic
          # Image type
          type: linux
          # Minimum virtual machine disk size in GB required by this image
          # for successfull installation
          min_disk: 4          

    # Install Cloud Orchestration Service
    heat:   
      # Orchestration service admin user name
      domain_admin: heat_admin
      # Orchestration service admin user password
      domain_admin_pass: password
    
    # Install OpenStack Dashboard Service
    horizon:
      # List of plugins to install for add Horizon support for
      # additional services
      plugins:
        # Plugin name
        heat-dashboard:
          # Dashboard name 
          check: orchestration
          # Dashboard settings file name
          settings: _1699_orchestration_settings.py
        
        neutron-fwaas-dashboard:  
          check: firewalls
          settings: _7000_neutron_fwaas.py

        murano-dashboard:
          check: muranodashboard
          settings: _50_murano.py  

    # Install OpenStack Telemetry services: Ceilometer, Aodh, Gnocchi
    # In this deployment are used Prometheus instead
    # For more information please refer to PROMETHEUS_AUTOSCALING.md

    # Install Time Series Database
#    gnocchi:

    # Install Data Collection Service
#    ceilometer:
      # Polling interval in seconds. accepted values are: 300, 60, 1
      # Corresponding to 'low', 'medium' and 'high' archive policys from gnocchi_resources.yaml
#      polling_interval: 60

    # Install Alarming Service
#    aodh:

    # Perfom varios postinstallation tasks
    # - creating networks
    # - security groups
    # - configure flavors
    # - upload glance images
    # etc..
    #
    # For more information refer to postinstall.pp manifest
    #
    postinstall:

```

Install OpenStack

```
	include openstack::install
```


### 3. Known backgrounds and issues
Not found yet


### 4. Used documentation

https://docs.openstack.org


