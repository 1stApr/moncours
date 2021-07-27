# Gnocchi documentation: https://gnocchi.osci.io/operating.html?highlight=uwsgi
#
class openstack::gnocchi::install inherits openstack::install {


  # current module local constants
  #
  # /etc/gnocchi/gnocchi.conf
  #
  $configs = ['gnocchi.conf']

  #
  $system_services = ['gnocchi-api', 'gnocchi-metricd']



  # create database
  openstack::utils::database { "create_database_${service}":
    dbname          => $service,
    dbrootpassword  => $dbrootpassword,
    dbuser          => $service,
    dbpass          => $password
  }

  # create system user and required folders
  openstack::utils::user { "create_user_${service}":
    service => $service,
    depends => Openstack::Utils::Database["create_database_${service}"]
  }

  # configure logrotate
  openstack::utils::logrotate { "${service}_logrotate":
    service => $service,
    threshold => $logthreshold,
    keep => $logkeep,
    depends => Openstack::Utils::User["create_user_${service}"]
  }

  # install gnocchi via pip3 install
  exec { "install_${service}":
    command => '/usr/bin/pip3 install gnocchi[mysql,file,keystone]',
    provider => 'shell',
    creates => '/usr/local/bin/gnocchi-upgrade',
    require => Openstack::Utils::User["create_user_${service}"]
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "gnocchi_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Exec["install_${service}"]
    }
  }

  # populate gnocchi database
  openstack::utils::database::populate { 'populate_gnocchi_database':
    service  => $service,
    password => $password,
    command  => '/usr/local/bin/gnocchi-upgrade',
    table    => 'metric',      
    depends => [Exec["install_${service}"],
                File['/etc/gnocchi/gnocchi.conf']]
  }

  # /etc/gnocchi/uwsgi-gnocchi-api.ini              
  openstack::utils::uwsgi { 'uwsgi_gnocchi_api':
    service => $service,
    unit    => 'gnocchi-api',
    port    => 8041,
    reload  => Service[$system_services],
    depends => Openstack::Utils::Database::Populate['populate_gnocchi_database']
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Openstack::Utils::Uwsgi['uwsgi_gnocchi_api']
    }
  }

  # create gnocchi-api apache site config
  openstack::utils::website { 'enable_uwsgi_gnocchi_api':
    site     => 'uwsgi-gnocchi-api',
    service  => $service,
    port     => 8041,
    proxy    => 'metric',
    depends  => Service[$system_services]
  }

  # openstack user create --domain default --password ${password} gnocchi
  # openstack role add --project service --user gnocchi admin
  # openstack service create --name ${service} --description "Metric Service" metric
  # openstack endpoint create --region ${region} metric public http://${management_ip}/metric
  # openstack endpoint create --region ${region} metric admin http://${management_ip}/metric
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
    "openstack_create_service_${service}" => [ "openstack service create --name ${service} --description 'Metric Time Series Database Service' metric", "openstack service list | /bin/grep metric" ],
    "openstack_create_endpoint_public_${service}" => [ "openstack endpoint create --region ${region} metric public http://${management_ip}/metric", "openstack endpoint list | /bin/grep 'metric.*public'" ],
    "openstack_create_endpoint_admin_${service}" => [ "openstack endpoint create --region ${region} metric admin http://${management_ip}/metric", "openstack endpoint list | /bin/grep 'metric.*admin'" ],
  }

  openstack::utils::bulkrun { 'setup_gnocchi_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    Openstack::Utils::Website['enable_uwsgi_gnocchi_api']]
  }

}
