class openstack::glance::install inherits openstack::install {


  # current module local constants
  #
  # /etc/glance/glance-api.conf
  # /etc/glance/glance-api-paste.ini
  # /etc/glance/glance-registry.conf
  # /etc/glance/glance-registry-paste.ini
  # /etc/glance/schema-image.json
  $configs = ['glance-api.conf', 'glance-api-paste.ini', 'glance-registry.conf', 
              'glance-registry-paste.ini', 'schema-image.json']

  # glance system services
  $system_services = ['glance-api', 'glance-registry']


  # setup glance prerequisites
  openstack::utils::prerequisites { 'glance_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/glance-manage',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "glance_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['glance_prerequisites']
    }
  }

  # /etc/glance/uwsgi-glance-api.ini
  openstack::utils::uwsgi { 'uwsgi_glance_api':
    service => $service,
    unit    => 'glance-api',
    port    => $glance_port,
    reload  => Service[$system_services],
    depends => File['/etc/glance/glance-api.conf']
  }

  # generate policy
  openstack::utils::policy { 'glance_policy':
    service => $service,
    config  => '/etc/glance/glance-api.conf',
    depends => File['/etc/glance/glance-api.conf']
  }

  # populate glance database
  openstack::utils::database::populate { 'populate_glance_database':
    service  => $service,
    password => $password,
    command  => '/usr/local/bin/glance-manage db_sync',
    table    => 'images',
    depends  => Openstack::Utils::Uwsgi['uwsgi_glance_api']
  }

  # create image store folders
  file { [$image_store,
          $image_download_dir]: 
    ensure => 'directory',
    owner => $service,
    group => $service,
    require => Openstack::Utils::Database::Populate['populate_glance_database']
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Openstack::Utils::Database::Populate['populate_glance_database']
    }
  }

  # create glance-api apache site config
  openstack::utils::website { 'enable_uwsgi_glance_api':
    site     => 'uwsgi-glance-api',
    service  => $service,
    port     => $glance_port,
    proxy    => $glance_proxy,
    depends  => Service[$system_services]
  }

  # openstack user create --domain default --password ${password} glance
  # openstack role add --project service --user glance admin
  # openstack service create --name ${service} --description "OpenStack Image Service" image
  # openstack endpoint create --region ${region} image public http://${management_ip}/image
  # openstack endpoint create --region ${region} image admin http://${management_ip}/image
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
    "openstack_create_service_${service}" => [ "openstack service create --name ${service} --description 'OpenStack Image Service' ${glance_proxy}", "openstack service list | /bin/grep ${service}" ],
    "openstack_create_endpoint_public_${service}" => [ "openstack endpoint create --region ${region} ${glance_proxy} public http://${management_ip}/${glance_proxy}", "openstack endpoint list | /bin/grep '${service}.*public'" ],
    "openstack_create_endpoint_admin_${service}" => [ "openstack endpoint create --region ${region} ${glance_proxy} admin http://${management_ip}/${glance_proxy}", "openstack endpoint list | /bin/grep '${service}.*admin'" ],
  }

  openstack::utils::bulkrun { 'setup_glance_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    Openstack::Utils::Website['enable_uwsgi_glance_api']]
  }

  # upload OS images
  openstack::utils::image { 'upload_glance_OS_images':
    images      => $glance_images,
    store       => $image_download_dir,
    environment => $environment,
    depends     => Openstack::Utils::Bulkrun['setup_glance_credentials']
  }

}


