class openstack::keystone::install inherits openstack::install {

  # current module local constants
  #
  # /etc/keystone/keystone.conf
  $configs = ['keystone.conf' ]

  # keystone system services
  $system_services = ['keystone-admin', 'keystone-public']


  # setup keystone prerequisites
  openstack::utils::prerequisites { 'keystone_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/keystone-manage',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "keystone_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['keystone_prerequisites']
    }
  }
  
  # create uwsgi servers configuration files
  # /etc/keystone/uwsgi-keystone-public.ini
  openstack::utils::uwsgi { 'uwsgi_keystone_public':
    service => $service,
    unit    => 'keystone-public',
    port    => $keystone_port,
    reload  => Service[$system_services],
    depends => File['/etc/keystone/keystone.conf']
  }

  # /etc/keystone/uwsgi-keystone-admin.ini
  openstack::utils::uwsgi { 'uwsgi_keystone_admin':
    service => $service,
    unit    => 'keystone-admin',
    port    => $keystone_port_admin,
    reload  => Service[$system_services],
    depends => File['/etc/keystone/keystone.conf']
  }

  # generate policy
  openstack::utils::policy { 'keystone_policy':
    service => $service,
    depends => File['/etc/keystone/keystone.conf']
  }

  # populate keystone database
  openstack::utils::database::populate { 'populate_keystone_database':
    service  => $service,
    password => $password,
    command  => '/usr/local/bin/keystone-manage db_sync',
    table    => 'region',
    depends  => [Openstack::Utils::Uwsgi['uwsgi_keystone_public'],
                 Openstack::Utils::Uwsgi['uwsgi_keystone_admin']]
  }

  # Initialize Fernet key repositories
  exec { 'initialize_key_repositories':
    command => "/usr/local/bin/keystone-manage fernet_setup --keystone-user ${service} --keystone-group ${service} \
             && /usr/local/bin/keystone-manage credential_setup --keystone-user ${service} --keystone-group ${service}",
    provider => 'shell',
    require => Openstack::Utils::Database::Populate['populate_keystone_database'],
    creates => [ "/etc/${service}/fernet-keys/0",
                 "/etc/${service}/fernet-keys/1" ],
  }

  /*
    in production environment configure keys rotation

    The keystone-manage command line utility includes a key rotation mechanism. 
    This mechanism will initialize and rotate keys but does not make an effort 
    to distribute keys across keystone nodes. The distribution of keys across a 
    keystone deployment is best handled through configuration management tooling. 
    Use 'keystone-manage fernet_rotate' to rotate the key repository.

    The fernet tokens that keystone creates are only secure as the keys creating 
    them. With staged keys the penalty of key rotation is low, allowing you to 
    err on the side of security and rotate weekly, daily, or even hourly. 
    Ultimately, this should be less time than it takes an attacker to break 
    a AES256 key and a SHA256 HMAC.

  */

  /*
    https://docs.openstack.org/keystone/train/admin/manage-trusts.html

    In the SQL trust stores expired and soft deleted trusts, that are not automatically removed. 
    These trusts can be removed with:

      $ keystone-manage trust_flush [options]

  */


  # bootstrap the Identity service
  exec { 'bootstrap_keystone':
    command => "/usr/local/bin/keystone-manage bootstrap \
                                          --bootstrap-username admin \
                                          --bootstrap-project-name ${project} \
                                          --bootstrap-password ${password} \
                                          --bootstrap-admin-url http://${management_ip}/identity_admin \
                                          --bootstrap-internal-url http://${management_ip}/identity \
                                          --bootstrap-public-url http://${management_ip}/identity \
                                          --bootstrap-region-id ${region}",
    user => $service,
    group => $service,
    provider => 'shell',
    require => Exec['initialize_key_repositories'],
    unless => "/usr/bin/mariadb -u ${service} \
                                -p${password} \
                                -e \"SELECT id FROM region;\" \
                                ${service} | /bin/grep ${region} ",
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => File["/etc/keystone/uwsgi-${unit}.ini"]
    }
  }

  # create keystone apache site configs
  openstack::utils::website { 'enable_uwsgi_keystone_public':
    site    => 'uwsgi-keystone-public',
    service => $service,
    port    => $keystone_port,
    proxy   => $keystone_proxy,
    depends  => Service[$system_services]
  }

  openstack::utils::website { 'enable_uwsgi_keystone_admin':
    site    => 'uwsgi-keystone-admin',
    service => $service,
    port    => $keystone_port_admin,
    proxy   => "${keystone_proxy}_admin",
    depends  => Service[$system_services]
  }

  # openstack domain create --description "${domain} domain" ${domain}
  # openstack project create --domain default --description "Service Project" service
  # openstack project create --domain ${domain} --description "Main Project" ${project}
  # openstack role add --project ${project} --user admin admin
  #
  $commands = {
    "create_domain" => [ "openstack domain create --description '${domain} domain' ${domain}", "openstack domain list | /bin/grep ${domain}" ],
    "create_project_service" => [ "openstack project create --domain default --description 'Service Project' service", "openstack project list | /bin/grep service" ],
    "create_project_${project}" => [ "openstack project create --domain ${domain} --description '${project} Project' ${project}", "openstack project list | /bin/grep ${project}" ],
  }

  openstack::utils::bulkrun { 'setup_keystone_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => Openstack::Utils::Website['enable_uwsgi_keystone_public']
  }

  # create openrc file
  file { $credentials_file:
    ensure => present,
    owner => 'root',
    group => 'root',
    content => template('openstack/keystone/openrc.erb'),
    require => Exec['bootstrap_keystone']
  }
 
}
