class openstack::aodh::install inherits openstack::install {


  # current module local constants
  #
  $configs = ['aodh.conf']


  # aodh system services
  #
  $system_services = ['aodh-api', 'aodh-evaluator', 'aodh-listener', 'aodh-notifier']


  # setup aodh prerequisites
  openstack::utils::prerequisites { 'aodh_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/aodh-dbsync',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "aodh_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['aodh_prerequisites']
    }
  }

  # populate aodh database
  openstack::utils::database::populate { 'populate_aodh_database':
    service  => $service,
    password => $password,
    command  => '/usr/local/bin/aodh-dbsync',
    table    => 'alarm',      
    depends => [Openstack::Utils::Prerequisites['aodh_prerequisites'],
                File['/etc/aodh/aodh.conf']]
  }

  # /etc/aodh/uwsgi-aodh-api.ini              
  openstack::utils::uwsgi { 'uwsgi_aodh_api':
    service => $service,
    unit    => 'aodh-api',
    port    => 8042,
    reload  => Service[$system_services],
    depends => Openstack::Utils::Database::Populate['populate_aodh_database']
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Openstack::Utils::Uwsgi['uwsgi_aodh_api']
    }
  }

  # create aodh-api apache site config
  openstack::utils::website { 'enable_uwsgi_aodh_api':
    site     => 'uwsgi-aodh-api',
    service  => $service,
    port     => 8042,
    proxy    => 'alarming',
    depends  => Service[$system_services]
  }

  # openstack user create --domain default --password ${password} aodh
  # openstack role add --project service --user aodh admin
  # openstack service create --name ${service} --description "Telemetry Alarming Service" alarming
  # openstack endpoint create --region ${region} alarming public http://${management_ip}/alarming
  # openstack endpoint create --region ${region} alarming admin http://${management_ip}/alarming
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
    "openstack_create_service_${service}" => [ "openstack service create --name ${service} --description 'Telemetry Alarming Service' alarming", "openstack service list | /bin/grep alarming" ],
    "openstack_create_endpoint_public_${service}" => [ "openstack endpoint create --region ${region} alarming public http://${management_ip}/alarming", "openstack endpoint list | /bin/grep '${service}.*public'" ],
    "openstack_create_endpoint_admin_${service}" => [ "openstack endpoint create --region ${region} alarming admin http://${management_ip}/alarming", "openstack endpoint list | /bin/grep '${service}.*admin'" ],
  }
  
  openstack::utils::bulkrun { 'setup_aodh_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    Openstack::Utils::Website['enable_uwsgi_aodh_api']]
  }


}
