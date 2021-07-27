class openstack::ceilometer::install inherits openstack::install {


  # current module local constants
  #
  # /etc/ceilometer/ceilometer.conf
  # /etc/ceilometer/rootwrap.conf
  # /etc/ceilometer/pipeline.yaml
  # /etc/ceilometer/polling.yaml 
  # /etc/ceilometer/gnocchi_resources.yaml
  $configs = ['ceilometer.conf', 'rootwrap.conf', 'pipeline.yaml', 'polling.yaml', 'gnocchi_resources.yaml']


  # ceilometer system services
  #
  # ceilometer-agent-compute - compute node agent
  #
  $system_services = ['ceilometer-agent-central', 'ceilometer-agent-notification', 'ceilometer-agent-compute']


  # setup ceilometer prerequisites
  openstack::utils::prerequisites { 'ceilometer_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/ceilometer-status',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "ceilometer_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['ceilometer_prerequisites']
    }
  }

  # openstack user create --domain default --password ${password} ceilometer
  # openstack role add --project service --user ceilometer admin
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
  }

  openstack::utils::bulkrun { 'setup_ceilometer_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    File['/etc/ceilometer/ceilometer.conf']]
  }

  # upgrade gnocchi database
  exec { 'ugrade_gnocchi_database':
    command => 'ceilometer-upgrade',
    provider => 'shell',
    group => $service,
    user => $service,
    environment => $environment,
    unless => "/usr/bin/mariadb -u gnocchi \
                                -p${password} \
                                -e \"select name from resource_type;\" \
                                gnocchi | /bin/grep stack",
    require => [Class['Openstack::Gnocchi::Install'],
                Openstack::Utils::Bulkrun['setup_ceilometer_credentials']]
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Exec['ugrade_gnocchi_database']
    }
  }

}
