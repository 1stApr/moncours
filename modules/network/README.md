### 0. Description
This module configure host ip network interfaces and adds 
/etc/hosts file records with values from Hiera yaml. 
Interface IP address configuration can be 'static ip' or 'dhcp'
This module uses netplan for ip network configuration.
Also this module can manage 'ip_forwarding' and 'ip v6 support' 
network kernel parameters with sysctl utility.


### 1. Tested environments
This module developed and tested on Ubuntu 18.04 only


### 2. Usage
Add to corresponding Hiera yaml file host network configuration:

*Parameters 'gateway', 'dns' and 'mtu' on all interface types*
*are optional. You can provide it or not.*



```
network:
  ip_forwarding: true
  ip_v6: false

  interfaces:

    # Interface with static ip
    ens3:
      ip: 10.64.10.100/24                   
      gateway: 10.64.10.1                   
      dns: 8.8.8.8                          
      mtu: 1500
      hostname: openstack
      comment: OpenStack server

    # Interface with dhcp
    enp0s4:
      ip: dhcp

    # Bridge interface
    br-ex:
      members: 
        - enp0s5        
      ip: 10.64.10.101/24                   
      gateway: 10.64.10.1                   
      dns: 8.8.8.8       
      mtu: 1500                   
      hostname: openstack-bridge
      comment: OpenStack server  

```

And include class in proper place

```
include network
```


### 3. Known backgrounds and issues
This module doesn't have support for interface bonding.


### 4. Used documentation
Ubuntu 18 netplan: https://linuxconfig.org/how-to-configure-static-ip-address-on-ubuntu-18-04-bionic-beaver-linux

Refacter: https://github.com/onpuppet/puppet-refacter

