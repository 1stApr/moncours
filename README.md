### 0. download and install ubuntu mini

    https://help.ubuntu.com/community/Installation/MinimalCD


### 1. disable Spectre and Meltdown patches 

*This step is optional*
*If you don't wont disable security pathes you can skip it*

*Options: https://wiki.ubuntu.com/SecurityTeam/KnowledgeBase/SpectreAndMeltdown/MitigationControls*


```    
    sudo vi /etc/default/grub
    
    GRUB_CMDLINE_LINUX_DEFAULT="splash quiet pti=off kpti=off spectre_v2=off spec_store_bypass_disable=off"

    sudo update-grub
    sudo init 6
```

### 2. install git

```
    sudo apt update
    sudo apt install git
```

### 3. install puppet

```
    wget https://apt.puppetlabs.com/puppet6-release-bionic.deb
    sudo dpkg -i puppet6-release-bionic.deb 
    sudo apt update
    sudo apt install puppet-agent
    
    # add to PATH
    sudo vi /etc/environment 
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/puppetlabs/bin"
```


### 4. check and disable unnecessarily services

*This step is optional. You can skip it*

```    
    systemctl list-units *.service
    
    sudo systemctl disable ufw
    sudo systemctl disable apparmor
    sudo systemctl disable puppet
    sudo systemctl disable apt-daily.timer 
```


### 5. clone repository

```
    git clone https://alexey_smovzh@bitbucket.org/alexey_smovzh/openstack_from_source.git
```

### 6. edit openstack.yaml

*For all available options please read OpenStack module [README.md](modules/openstack/README.md)*

```
    vi openstack/hiera/openstack.yaml
```

### 7. run puppet

```
    sudo /opt/puppetlabs/bin/puppet apply --hiera_config ~/openstack/hiera.yaml --modulepath ~/openstack/modules ~/openstack/manifests/site.pp
```

### 8. login to OpenStack dashboard

   https://<openstack_public_ip>/dashboard


## asciinema record of actual deployment 

[![asciicast](https://asciinema.org/a/317826.svg)](https://asciinema.org/a/317826?speed=6&autoplay=1)

