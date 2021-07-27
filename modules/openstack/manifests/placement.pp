class openstack::placement::install inherits openstack::install {


  # current module local constants
  #
  # /etc/placement/placement.conf
  $configs = ['placement.conf']

  # placement system services
  $system_services = ['placement']


  # setup placement prerequisites
  openstack::utils::prerequisites { 'placement_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/placement-manage',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "placement_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['placement_prerequisites']
    }
  }

  # /etc/placement/uwsgi-placement.ini
  openstack::utils::uwsgi { 'uwsgi_placement':
    service => $service,
    unit    => 'placement',
    port    => $placement_port,
    reload  => Service[$system_services],
    depends => File['/etc/placement/placement.conf']
  }

  # populate placement database
  openstack::utils::database::populate { 'populate_placement_database':
    service  => $service,
    password => $password,
    command  => '/usr/local/bin/placement-manage db sync',
    table    => 'traits',
    depends  => Openstack::Utils::Uwsgi['uwsgi_placement']
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Openstack::Utils::Database::Populate['populate_placement_database']
    }
  }

  # create placement apache site config
  openstack::utils::website { 'enable_uwsgi_placement':
    site     => 'uwsgi-placement',
    service  => $service,
    port     => $placement_port,
    proxy    => $placement_proxy,
    depends  => Service[$system_services]
  }

  # openstack user create --domain default --password ${password} placement
  # openstack role add --project service --user placement admin
  # openstack service create --name ${service} --description "Placement API" placement
  # openstack endpoint create --region ${region} placement public http://${management_ip}/placement
  # openstack endpoint create --region ${region} placement admin http://${management_ip}/placement
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
    "openstack_create_service_${service}" => [ "openstack service create --name ${service} --description 'Placement API' ${placement_proxy}", "openstack service list | /bin/grep ${service}" ],
    "openstack_create_endpoint_public_${service}" => [ "openstack endpoint create --region ${region} ${placement_proxy} public http://${management_ip}/${placement_proxy}", "openstack endpoint list | /bin/grep '${service}.*public'" ],
    "openstack_create_endpoint_admin_${service}" => [ "openstack endpoint create --region ${region} ${placement_proxy} admin http://${management_ip}/${placement_proxy}", "openstack endpoint list | /bin/grep '${service}.*admin'" ],
  }

  openstack::utils::bulkrun { 'setup_placement_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    Openstack::Utils::Website['enable_uwsgi_placement']]
  }
 
}
