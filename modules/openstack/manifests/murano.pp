# https://docs.openstack.org/murano/train/install/
# https://github.com/openstack/murano-apps/tree/master/ZabbixServer/package
#
class openstack::murano::install inherits openstack::install {

  # current module local constants
  #
  # /etc/murano/murano.conf
  $configs = ['murano.conf', 'murano-paste.ini']

  # murano system services
  $system_services = ['murano-api', 'murano-engine']


  # setup murano prerequisites
  openstack::utils::prerequisites { 'murano_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/murano-db-manage',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "murano_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['murano_prerequisites']
    }
  }

  # /etc/murano/uwsgi-murano-api.ini
  openstack::utils::uwsgi { 'uwsgi_murano_api':
    service => $service,
    unit    => 'murano-api',
    port    => $murano_port,
    reload  => Service[$system_services],
    depends => File['/etc/murano/murano.conf']
  }
  
  # generate policy
  openstack::utils::policy { 'murano_policy':
    service => $service,
    sample  => "${root}/${service}/etc/oslo-policy-generator/murano-policy-generator.conf",
    depends => File['/etc/murano/murano.conf']
  }

  # populate murano database
  openstack::utils::database::populate { 'populate_murano_database':
    service  => $service,
    password => $password,
    command  => '/usr/local/bin/murano-db-manage upgrade',
    table    => 'package',
    depends  => Openstack::Utils::Uwsgi['uwsgi_murano_api']
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Openstack::Utils::Database::Populate['populate_murano_database']
    }
  }

  # create murano-api apache site config
  openstack::utils::website { 'enable_uwsgi_murano_api':
    site     => 'uwsgi-murano-api',
    service  => $service,
    port     => $murano_port,
    proxy    => $murano_proxy,
    depends  => Service[$system_services]
  }

  # openstack user create --domain default --password ${password} murano
  # openstack role add --project service --user murano admin
  # openstack service create --name ${service} --description "Application Catalog" application-catalog
  # openstack endpoint create --region ${region} application-catalog public http://${management_ip}/application-catalog
  # openstack endpoint create --region ${region} application-catalog admin http://${management_ip}/application-catalog
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],        
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
    "openstack_create_service_${service}" => [ "openstack service create --name ${service} --description 'Application Catalog' ${murano_proxy}", "openstack service list | /bin/grep -w ${service}" ],    
    "openstack_create_endpoint_public_${service}" => [ "openstack endpoint create --region ${region} ${murano_proxy} public http://${management_ip}/${murano_proxy}", "openstack endpoint list | /bin/grep '${service}.*public'" ],
    "openstack_create_endpoint_admin_${service}" => [ "openstack endpoint create --region ${region} ${murano_proxy} admin http://${management_ip}/${murano_proxy}", "openstack endpoint list | /bin/grep '${service}.*admin'" ],
  }

  openstack::utils::bulkrun { 'setup_murano_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    Openstack::Utils::Website['enable_uwsgi_murano_api']]
  }


  # upload murano core library 
  # https://murano.readthedocs.io/en/stable-liberty/appdev-guide/murano_pl/core_lib.html
  exec { 'upload_murano_core_library':
    command => "/usr/bin/zip -r ${root}/${service}/build/io.murano.zip * \
             && /usr/local/bin/murano --murano-url http://${management_ip}/${murano_proxy} package-import --is-public ${root}/${service}/build/io.murano.zip",
    provider => 'shell',
    cwd => "${root}/${service}/meta/io.murano",
    environment => $environment,
    unless => "/usr/local/bin/murano --murano-url http://${management_ip}/${murano_proxy} package-list | /bin/grep io.murano",  
    require => Openstack::Utils::Bulkrun['setup_murano_credentials']    
  }

  # upload murano applications library 
  exec { 'upload_murano_applications_library':
    command => "/usr/bin/zip -r ${root}/${service}/build/io.murano.applications.zip * \
             && /usr/local/bin/murano --murano-url http://${management_ip}/${murano_proxy} package-import --is-public ${root}/${service}/build/io.murano.applications.zip",
    provider => 'shell',
    cwd => "${root}/${service}/meta/io.murano.applications",
    environment => $environment,
    unless => "/usr/local/bin/murano --murano-url http://${management_ip}/${murano_proxy} package-list | /bin/grep io.murano.applications",  
    require => Openstack::Utils::Bulkrun['setup_murano_credentials']    
  }

  # upload OS images
  openstack::utils::image_murano { 'upload_murano_OS_images':
    images      => $murano_images,
    store       => $murano_image_build_dir,
    root        => $root,
    environment => $environment,
    service     => $service,
    depends     => Openstack::Utils::Bulkrun['setup_murano_credentials']
  }

}
