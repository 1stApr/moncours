class openstack::neutron::install inherits openstack::install {

  # current module local constants
  #
  # /etc/neutron/neutron.conf
  # /etc/neutron/plugins/ml2/ml2_conf.ini 
  # /etc/neutron/plugins/ml2/linuxbridge_agent.ini
  # /etc/neutron/l3_agent.ini
  # /etc/neutron/dhcp_agent.ini
  # /etc/neutron/metadata_agent.ini 
  # /etc/neutron/neutron_vpnaas.conf
  # /etc/neutron/rootwrap.conf
  # /etc/neutron/api-paste.ini 
  #
  $configs = ['neutron.conf', 'l3_agent.ini', 'dhcp_agent.ini', 'metadata_agent.ini', 'api-paste.ini',
              'rootwrap.conf', 'neutron_vpnaas.conf', 'plugins/ml2/ml2_conf.ini', 
              'plugins/ml2/linuxbridge_agent.ini' ]

  # Neutron services
  $system_services = ['neutron-server', 'neutron-linuxbridge-agent', 'neutron-dhcp-agent', 
              'neutron-metadata-agent', 'neutron-l3-agent' ]

  # neutron rootwrap filters
  $filters = ['debug.filters', 'dhcp.filters', 'dibbler.filters', 'ebtables.filters', 'ipset-firewall.filters', 
              'iptables-firewall.filters', 'l3.filters', 'linuxbridge-plugin.filters', 'netns-cleanup.filters',
              'openvswitch-plugin.filters', 'privsep.filters', 'fwaas-privsep.filters', 'vpnaas.filters']


  # neutron use some linux network subsystem kernel modules
  # list of modules provided in Hiera yaml file under neutron section
  $kernel_modules.each |$module| {

    # load module if it not loaded already
    exec { "${service}_load_module_${module}":
      command => "/sbin/modprobe ${module}",
      user => 'root',
      group => 'root',
      unless => "/sbin/lsmod | /usr/bin/awk '{ print $1 }' | /bin/grep ${module}",
      before => Openstack::Utils::Prerequisites['neutron_prerequisites']
    }

    # enable module to load during system boot
    exec { "${service}_enable_module_${module}":
      command => "/bin/echo ${module} >> /etc/modules",
      user => 'root',
      group => 'root',
      unless => "/bin/grep -zoP '${module}\\n' /etc/modules",
      before => Openstack::Utils::Prerequisites['neutron_prerequisites']
    }
  }

  # setup neutron prerequisites
  openstack::utils::prerequisites { 'neutron_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    filters         => $filters,
    sudoers         => template('openstack/neutron/neutron.sudoers.erb'),
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/neutron-server',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "neutron_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['neutron_prerequisites']
    }
  }

  # generate policy
  openstack::utils::policy { 'neutron_policy':
    service => $service,
    config  => '/etc/neutron/neutron.conf',
    depends => File['/etc/neutron/neutron.conf']
  }

  # populate neutron database
  openstack::utils::database::populate { 'populate_neutron_database':
    service  => $service,
    password => $password,
    command  => '/usr/local/bin/neutron-db-manage --config-file /etc/neutron/neutron.conf \
                                                  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini \
                                                  upgrade head',
    table    => 'routers',
    depends  => File['/etc/neutron/neutron.conf']
  }

  # install fwaas plugin
  class {'openstack::neutron_fwaas::install':
    depends => Openstack::Utils::Database::Populate['populate_neutron_database']
  }

  # install vpnaas plugin
  class {'openstack::neutron_vpnaas::install':
    depends => Openstack::Utils::Database::Populate['populate_neutron_database']
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Class['openstack::neutron_fwaas::install']
    }
  }

  # create neutron apache site config
  openstack::utils::website { 'enable_neutron_reverse_proxy':
    site     => 'neutron',
    service  => $service,
    port     => $neutron_port,
    proxy    => $neutron_proxy,
    pcontent => "ProxyPass '/${neutron_proxy}' 'http://${$management_ip}:${neutron_port}' retry=0",
    depends  => Service[$system_services]
  }

  # openstack user create --domain default --password ${password} neutron
  # openstack role add --project service --user neutron admin
  # openstack service create --name ${service} --description "OpenStack Networking" network
  # openstack endpoint create --region ${region} network public http://${management_ip}/network
  # openstack endpoint create --region ${region} network admin http://${management_ip}/network
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
    "openstack_create_service_${service}" => [ "openstack service create --name ${service} --description 'OpenStack Networking' ${neutron_proxy}", "openstack service list | /bin/grep ${service}" ],
    "openstack_create_endpoint_public_${service}" => [ "openstack endpoint create --region ${region} ${neutron_proxy} public http://${management_ip}/${neutron_proxy}", "openstack endpoint list | /bin/grep '${service}.*public'" ],   
    "openstack_create_endpoint_admin_${service}" => [ "openstack endpoint create --region ${region} ${neutron_proxy} admin http://${management_ip}/${neutron_proxy}", "openstack endpoint list | /bin/grep '${service}.*admin'" ],
  }

  openstack::utils::bulkrun { 'setup_neutron_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    Openstack::Utils::Website['enable_neutron_reverse_proxy']]
  }

}
