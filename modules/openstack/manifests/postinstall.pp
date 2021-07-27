# NOTE: !!!
#
# This manifest runs postinstall configuration tasks
# This tasks are specific for every particular OpenStack installation
# Examine this tasks and it parameters carefully if it suits to you
#
# Also during this manifest nature 
# there are a lot of 'spaghetty' code, hardcoded variables and 
# other coding anti patterns
#
class openstack::postinstall::install inherits openstack {

  # flavors
  $flavors = {
    'flavor_tiny' => [ "openstack flavor create --id c1 --ram 256 --disk 1 --vcpus 1 tiny", "openstack flavor list | /bin/grep -w tiny" ],
    'flavor_small' => [ "openstack flavor create --id c2 --ram 512 --disk 2 --vcpus 1 small", "openstack flavor list | /bin/grep -w small" ],
    'flavor_medium' => [ "openstack flavor create --id c3 --ram 1024 --disk 4 --vcpus 1 medium", "openstack flavor list | /bin/grep -w medium" ],
    'flavor_large' => [ "openstack flavor create --id c4 --ram 2048 --disk 10 --vcpus 1 large", "openstack flavor list | /bin/grep -w large" ],
    'flavor_huge' => [ "openstack flavor create --id c5 --ram 4096 --disk 10 --vcpus 1 huge", "openstack flavor list | /bin/grep -w huge" ],
    'flavor_db_small' => [ "openstack flavor create --id db1 --ram 2048 --disk 4 --vcpus 1 db.small", "openstack flavor list | /bin/grep -w db.small" ]
  }

  openstack::utils::bulkrun { 'create_flavors':
    commands    => $flavors,
    environment => $environment,
    depends     => Class['Openstack::Nova::Install']
  }



  # initial network configuration
  #
  $dns = $neutron_provider['dns']
  $range = $neutron_provider['range']
  $gw = $neutron_provider['gateway']
  
  case $network_type {
    'bridge': {
                # openstack network create --share --external --provider-physical-network provider 
                #                                  --provider-network-type flat infrastructure
                # openstack subnet create --network infrastructure --subnet-range 10.64.10.0/24 
                #                         --gateway 10.64.10.1 --dns-nameserver 8.8.8.8 
                #                         --allocation-pool start=10.64.10.120,end=10.64.10.160 infrastructure-subnet
                #  
                # openstack network create NET1
                # openstack subnet create --subnet-range 192.168.1.0/24 --network NET1 --dns-nameserver 8.8.8.8 SUBNET1
                # openstack router create BORDER
                # openstack router add subnet BORDER SUBNET1
                # openstack router set --external-gateway PROVIDER1 BORDER
                $networks = {
                  'NET1' => [ "openstack network create NET1", "openstack network list | /bin/grep NET1"],
                  'SUBNET1' => [ "openstack subnet create --subnet-range 192.168.0.0/24 --network NET1 --dns-nameserver ${dns} SUBNET1", "openstack subnet list | /bin/grep SUBNET1"],
                  'PROVIDER1' => [ "openstack network create --share --external --provider-physical-network provider --provider-network-type flat PROVIDER1", "openstack network list | /bin/grep PROVIDER1"],
                  'PROVIDER1-v4' => [ "openstack subnet create --subnet-range ${range} --gateway ${gw} --network PROVIDER1 --allocation-pool start=10.64.10.200,end=10.64.10.250 --dns-nameserver ${dns} PROVIDER1-v4", "openstack subnet list | /bin/grep PROVIDER1-v4"],
                  'BORDER1' => [ "openstack router create BORDER1", "openstack router list | /bin/grep BORDER1"],
                  'BORDER1_PRIVATE' => [ "openstack router add subnet BORDER1 SUBNET1", "openstack port list --network NET1 --router BORDER1 --fixed-ip subnet=SUBNET1 | /bin/grep ACTIVE"],
                  'BORDER1_GATEWAY' => [ "openstack router set --external-gateway PROVIDER1 BORDER1", "openstack router list --long | /bin/grep external"]
                }
    }

    'vlan': {
                # openstack network create --share --external --provider-physical-network provider 
                #                          --provider-network-type vlan --provider-segment 40 businessapp
                #
                # openstack subnet create --network external 
                #                         --allocation-pool start=10.64.40.10,end=10.64.40.254 
                #                         --no-dhcp --dns-nameserver 8.8.8.8 --gateway 10.64.40.1 
                #                         --subnet-range 10.64.40.0/24 app-subnet
                $networks = {
                  'infrastructure' => [ "openstack network create --share --external --provider-physical-network provider --provider-network-type vlan --provider-segment 40 infrastructure", "openstack network list | /bin/grep infrastructure"],
                  'infr-subnet' => [ "openstack subnet create --network infrastructure --allocation-pool start=10.64.40.10,end=10.64.40.254 --dns-nameserver ${dns} --gateway 10.64.40.1 --subnet-range 10.64.40.0/24 infr-subnet", "openstack subnet list | /bin/grep infr-subnet"],
                  'businessapp' => [ "openstack network create --share --external --provider-physical-network provider --provider-network-type vlan --provider-segment 50 businessapp", "openstack network list | /bin/grep businessapp"],
                  'app-subnet' => [ "openstack subnet create --network businessapp --allocation-pool start=10.64.50.10,end=10.64.50.254 --dns-nameserver ${dns} --gateway 10.64.50.1 --subnet-range 10.64.50.0/24 app-subnet", "openstack subnet list | /bin/grep app-subnet"],
                  'murano' => [ "openstack network create --share --external --provider-physical-network provider --provider-network-type vlan --provider-segment 60 murano", "openstack network list | /bin/grep murano"],
                  'murano-subnet' => [ "openstack subnet create --network murano --allocation-pool start=10.64.60.10,end=10.64.60.254 --dns-nameserver ${dns} --gateway 10.64.60.1 --subnet-range 10.64.60.0/24 murano-subnet", "openstack subnet list | /bin/grep murano-subnet"],
                }
    }    
  }

#  openstack::utils::bulkrun { 'create_network_configuration':
 #   commands    => $networks,
  #  environment => $environment,
   # depends     => Class['Openstack::Neutron::Install']
  #}

  # security groups
  #
  # openstack security group create basic --description 'Allow ICMP and SSH for hosts from our network' 
  # openstack security group rule delete $(openstack security group rule list basic | grep '0.0.0.0/0' | awk '{print $2}')
  # openstack security group rule delete $(openstack security group rule list basic | grep '::/0' | awk '{print $2}')
  # openstack security group rule create basic --protocol icmp --ingress --description 'ICMP from our network' --remote-ip 10.64.0.0/16
  # openstack security group rule create basic --protocol icmp --egress --description 'ICMP to our network' --remote-ip 10.64.0.0/16
  # openstack security group rule create basic --protocol tcp --dst-port 22:22 --description 'SSH from our network' --remote-ip 10.64.0.0/16
  $rules = {
    # allow ICMP, SSH, outgoing DNS for 8.8.8.8 and outgoing http and https for updates for all VMs
    'create_group_basic' => ["openstack security group create basic --description 'Allow ICMP and SSH for hosts from our network'", "openstack security group list | /bin/grep basic"],
    'basic_delete_default_ipv4_rule' => ["openstack security group rule delete \$(openstack security group rule list basic | /bin/grep '0.0.0.0/0' | /usr/bin/awk '{print \$2}')", "openstack security group rule list basic | /bin/grep 'None.*0.0.0.0/0'; /usr/bin/test \$? -eq 1"],
    'basic_delete_default_ipv6_rule' => ["openstack security group rule delete \$(openstack security group rule list basic | /bin/grep '::/0' | /usr/bin/awk '{print \$2}')", "openstack security group rule list basic | /bin/grep 'None.*::/0'; /usr/bin/test \$? -eq 1"],
    'basic_allow_icmp_ingress' => ["openstack security group rule create basic --protocol icmp --ingress --description 'ICMP from our network' --remote-ip 10.64.0.0/16", "openstack security group rule list basic --long | /bin/grep -w 'icmp.*ingress'"],
    'basic_allow_icmp_egress' => ["openstack security group rule create basic --protocol icmp --egress --description 'ICMP to our network' --remote-ip 10.64.0.0/16", "openstack security group rule list basic --long | /bin/grep -w 'icmp.*egress'"],
    'basic_allow_ssh' => ["openstack security group rule create basic --protocol tcp --dst-port 22:22 --description 'SSH from our network' --remote-ip 10.64.0.0/16", "openstack security group rule list basic | /bin/grep -w 'tcp.*22:22'"],
    'basic_allow_dns' => ["openstack security group rule create basic --egress --protocol udp --dst-port 53:53 --description 'DNS requests from our network to google DNS' --remote-ip 8.8.8.8/32", "openstack security group rule list basic | /bin/grep -w 'udp.*53:53'"],
    'basic_allow_http' => ["openstack security group rule create basic --egress --protocol tcp --dst-port 80:80 --description 'Outbound HTTP from our network' --remote-ip 0.0.0.0/0", "openstack security group rule list basic | /bin/grep -w 'tcp.*80:80'"],
    'basic_allow_https' => ["openstack security group rule create basic --egress --protocol tcp --dst-port 443:443 --description 'Outbound HTTPS from our network' --remote-ip 0.0.0.0/0", "openstack security group rule list basic | /bin/grep -w 'tcp.*443:443'"], 
    # MySQL
    'create_group_mysql' => ["openstack security group create mysql --description 'MySQL database server traffic rules'", "openstack security group list | /bin/grep mysql"],
    'mysql_delete_default_ipv4_rule' => ["openstack security group rule delete \$(openstack security group rule list mysql | /bin/grep '0.0.0.0/0' | /usr/bin/awk '{print \$2}')", "openstack security group rule list mysql | /bin/grep 'None.*0.0.0.0/0'; /usr/bin/test \$? -eq 1"],
    'mysql_delete_default_ipv6_rule' => ["openstack security group rule delete \$(openstack security group rule list mysql | /bin/grep '::/0' | /usr/bin/awk '{print \$2}')", "openstack security group rule list mysql | /bin/grep 'None.*::/0'; /usr/bin/test \$? -eq 1"],
    'mysql_allow_sql_ingress' => ["openstack security group rule create mysql --ingress --protocol tcp --dst-port 3306:3306 --description 'Allow to 3306 from our private network' --remote-ip 10.64.0.0/16", "openstack security group rule list mysql | /bin/grep -w 'tcp.*3306:3306'"],
    # HTTP/S
    'create_group_http' => ["openstack security group create http --description 'HTTP/S web server traffic rules'", "openstack security group list | /bin/grep http"],
    'http_delete_default_ipv4_rule' => ["openstack security group rule delete \$(openstack security group rule list http | /bin/grep '0.0.0.0/0' | /usr/bin/awk '{print \$2}')", "openstack security group rule list http | /bin/grep 'None.*0.0.0.0/0'; /usr/bin/test \$? -eq 1"],
    'http_delete_default_ipv6_rule' => ["openstack security group rule delete \$(openstack security group rule list http | /bin/grep '::/0' | /usr/bin/awk '{print \$2}')", "openstack security group rule list http | /bin/grep 'None.*::/0'; /usr/bin/test \$? -eq 1"],
    'http_allow_http_ingress' => ["openstack security group rule create http --ingress --protocol tcp --dst-port 80:80 --description 'Allow to 80 from our private network' --remote-ip 10.64.0.0/16", "openstack security group rule list http | /bin/grep -w 'tcp.*80:80'"],
    'http_allow_https_ingress' => ["openstack security group rule create http --ingress --protocol tcp --dst-port 443:443 --description 'Allow to 443 from our private network' --remote-ip 10.64.0.0/16", "openstack security group rule list http | /bin/grep -w 'tcp.*443:443'"],
    # Prometheus Node Exporter
    'create_group_prometheus' => ["openstack security group create prometheus --description 'Prometheus node exporter traffic rules'", "openstack security group list | /bin/grep prometheus"],
    'prometheus_delete_default_ipv4_rule' => ["openstack security group rule delete \$(openstack security group rule list prometheus | /bin/grep '0.0.0.0/0' | /usr/bin/awk '{print \$2}')", "openstack security group rule list prometheus | /bin/grep 'None.*0.0.0.0/0'; /usr/bin/test \$? -eq 1"],
    'prometheus_delete_default_ipv6_rule' => ["openstack security group rule delete \$(openstack security group rule list prometheus | /bin/grep '::/0' | /usr/bin/awk '{print \$2}')", "openstack security group rule list prometheus | /bin/grep 'None.*::/0'; /usr/bin/test \$? -eq 1"],
    'prometheus_allow_node_exporter_ingress' => ["openstack security group rule create prometheus --ingress --protocol tcp --dst-port 9100:9100 --description 'Allow to 9100 from our private network' --remote-ip 10.64.0.0/16", "openstack security group rule list prometheus | /bin/grep -w 'tcp.*9100:9100'"]

  }


  openstack::utils::bulkrun { 'setup_security_groups':
    commands    => $rules,
    environment => $environment,
    depends     => Class['Openstack::Neutron::Install']
  }




  # adjust quotas
  $vcpu = $processorcount * 2
#  $ram = $memory['system']['total_bytes'] / 1024 / 1024 / 2
  $ram = 5 * 1024
  $instances = 4

  $quotas = {
    'quota_cores' => [ "openstack quota set --cores ${vcpu} --class default", "openstack quota show --default | /bin/grep 'cores.*${vcpu}'"],    
    'quota_ram' => [ "openstack quota set --ram ${ram} --class default", "openstack quota show --default | /bin/grep 'ram.*${ram}'"],    
    'quota_instances' => [ "openstack quota set --instances ${instances} --class default", "openstack quota show --default | /bin/grep 'instances.*${instances}'"]    
  }

  openstack::utils::bulkrun { 'set_default_quotas':
    commands    => $quotas,
    environment => $environment,
    depends     => [ Class['Openstack::Nova::Install'],
                     Class['Openstack::Neutron::Install'],
                     Class['Openstack::Glance::Install'],
                     Class['Openstack::Cinder::Install'] ]
  }




  # generate keys and store private key to user home .ssh directory
  exec { "generate_keys_${hostname}":
    command => "openstack keypair create --private-key /home/alex/.ssh/alex.pem alex \
             && /bin/chmod 400 /home/alex/.ssh/alex.pem \
             && eval \$(ssh-agent) \
             && /usr/bin/ssh-add /home/alex/.ssh/alex.pem",
    user => 'alex',             
    provider => 'shell',
    environment => $environment,
    require => [Class['Openstack::Nova::Install'],
                Class['Openstack::Neutron::Install']],
    unless => "openstack keypair list | /bin/grep alex"
  }




  # upload stack heat templates sources
  #
  # source ~/openstack.build/openrc
  # cd ~/openstack.build/heat_templates
  # openstack stack create -t cirros.yaml cirros_stack
  #
  file { 'heat_templates':
    path => "${root}/heat_templates",
    source => 'puppet:///modules/openstack/heat_templates',
    recurse => true,
    require => Class['Openstack::Heat::Install']
  }


  # upload murano apps sources
  # https://serverfault.com/questions/323111/how-do-i-recursively-mirror-a-directory-and-its-contents-with-puppet
  file { 'murano_apps':
    path => "${root}/murano_apps",
    source => 'puppet:///modules/openstack/murano_apps',
    notify => Exec['pack_upload_murano_apps'],
    recurse => true,
    require => Class['Openstack::Murano::Install']
  }

  # note: 'load_packages_from' option for murano-engine in murano.conf 
  #       to load packages from local dir instead upload archives
  exec { 'pack_upload_murano_apps':
    command => 'for i in $(/bin/ls -d */); do \
                  cd $i; \
                  /usr/bin/zip -r ${i%%/}.zip *; \
                  murano --murano-url http://127.0.0.1/application-catalog package-import --is-public --exists-action=u ${i%%/}.zip; \
                  /bin/rm -f ${i%%/}.zip; \
                  cd ../; \
                done',
    provider => 'shell',
    environment => $environment,
    cwd => "${root}/murano_apps",
    refreshonly => true,
  }                   

}  
