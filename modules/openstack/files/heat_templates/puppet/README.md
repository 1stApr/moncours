### 0. Description
This Heat template is a example how to assign Puppet roles and 
deploy apropriate services on instance based on openstack instance metadata


### 1. Tested environments
This module developed and tested on Debian 10 only.


### 2. Usage

Create stack

```
  openstack stack create -t openstack.build/heat_templates/puppet/puppet.yaml puppet
  
```

In puppet.yaml file in 'parameters' section are defined parameter 'role' with accepted 
values 'foo' or 'bar'. And as default it has value 'foo'. 

In 'server' section this parameter are assigned to instance as metadata 
with name 'puppet_role'.

'puppet.cloud-init' scenario installs puppet agent, creates 'site.pp' manifest
and 'puppet_role.sh' script. 'puppet_role.sh' script used to obtain 'puppet_role' 
metadata value as Puppet external fact. 

'puppet_role.sh' use curl to fetch instance metadata from nova and 'jq' program
to parce json response and extract metadata information.

'site.pp' using fact from 'puppet_role.sh' perfom required action via 'case' statement
and writes choosed message to '/puppet.result' file.

You can in any time change metadata value of instance 'puppet_role' tag. 
After that wait 10 minutes to next automatic puppet agent run and check execution result 
in '/puppet.result' file.


### 3. Known backgrounds and issues
none


### 4. Used documentation
none

