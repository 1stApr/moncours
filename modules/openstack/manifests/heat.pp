class openstack::heat::install inherits openstack::install {

  # current module local constants
  #
  # /etc/heat/heat.conf
  # /etc/heat/api-paste.ini
  $configs = ['heat.conf', 'api-paste.ini']

  # heat system services
  $system_services = ['heat-api', 'heat-api-cfn', 'heat-engine']


  # setup heat prerequisites
  openstack::utils::prerequisites { 'heat_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/heat-manage',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "heat_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['heat_prerequisites']
    }
  }

  # /etc/heat/uwsgi-heat-api.ini
  openstack::utils::uwsgi { 'uwsgi_heat_api':
    service => $service,
    unit    => 'heat-api',
    port    => $heat_port,
    reload  => Service[$system_services],
    depends => File['/etc/heat/heat.conf']
  }

  # /etc/heat/uwsgi-heat-api-cfn.ini
  openstack::utils::uwsgi { 'uwsgi_heat_api_cfn':
    service => $service,
    unit    => 'heat-api-cfn',
    port    => $heat_port_cfn,
    reload  => Service[$system_services],
    depends => File['/etc/heat/heat.conf']
  }

  # generate policy
  openstack::utils::policy { 'heat_policy':
    service => $service,
    config  => '/etc/heat/heat.conf',
    depends => File['/etc/heat/heat.conf']
  }

  # populate heat database
  openstack::utils::database::populate { 'populate_heat_database':
    service  => $service,
    password => $password,
    command  => '/usr/local/bin/heat-manage db_sync',
    table    => 'stack',
    depends  => [Openstack::Utils::Uwsgi['uwsgi_heat_api'],
                 Openstack::Utils::Uwsgi['uwsgi_heat_api_cfn']]
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Openstack::Utils::Database::Populate['populate_heat_database']
    }
  }

  # create heat-api apache site config
  openstack::utils::website { 'enable_uwsgi_heat_api':
    site     => 'uwsgi-heat-api',
    service  => $service,
    port     => $heat_port,
    proxy    => $heat_proxy,
    depends  => Service[$system_services]
  }

  # create heat-api-cfn apache site config
  openstack::utils::website { 'enable_uwsgi_heat_api_cfn':
    site     => 'uwsgi-heat-api-cfn',
    service  => $service,
    port     => $heat_port_cfn,
    proxy    => $heat_proxy_cfn,                 
    depends  => Service[$system_services]
  }

  # openstack user create --domain default --password ${password} heat
  # openstack role add --project service --user heat admin
  # openstack service create --name ${service} --description "Orchestration" orchestration
  # openstack service create --name ${service}-cfn --description "Orchestration" cloudformation
  # openstack endpoint create --region ${region} orchestration public http://${management_ip}/orchestration/v1/%\(project_id\)s
  # openstack endpoint create --region ${region} orchestration admin http://${management_ip}/orchestration/v1/%\(project_id\)s
  # openstack endpoint create --region ${region} cloudformation public http://${management_ip}/cloudformation/v1
  # openstack endpoint create --region ${region} cloudformation admin http://${management_ip}/cloudformation/v1
  # openstack domain create --description "Stack projects and users" heat
  # openstack user create --domain heat --password ${domain_admin_pass} ${domain_admin}
  # openstack role add --domain heat --user-domain heat --user ${domain_admin} admin
  # openstack role create heat_stack_owner
  # openstack role add --project ${project} --user admin heat_stack_owner
  # openstack role create heat_stack_user
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],    
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
    "openstack_create_service_${service}" => [ "openstack service create --name ${service} --description 'OpenStack Orchestration' ${heat_proxy}", "openstack service list | /bin/grep -w ${service}" ],
    "openstack_create_service_${service}_cfn" => [ "openstack service create --name ${service}_cfn --description 'OpenStack Orchestration' ${heat_proxy_cfn}", "openstack service list | /bin/grep -w ${service}_cfn" ],
    "openstack_create_endpoint_public_${service}" => [ "openstack endpoint create --region ${region} ${heat_proxy} public http://${management_ip}/${heat_proxy}/v1/%\\(project_id\\)s", "openstack endpoint list | /bin/grep '${service}.*public'" ],
    "openstack_create_endpoint_admin_${service}" => [ "openstack endpoint create --region ${region} ${heat_proxy} admin http://${management_ip}/${heat_proxy}/v1/%\\(project_id\\)s", "openstack endpoint list | /bin/grep '${service}.*admin'" ],
    "openstack_create_endpoint_public_${service}_cfn" => [ "openstack endpoint create --region ${region} ${heat_proxy_cfn} public http://${management_ip}/${heat_proxy_cfn}/v1", "openstack endpoint list | /bin/grep '${service}_cfn.*public'" ],
    "openstack_create_endpoint_admin_${service}_cfn" => [ "openstack endpoint create --region ${region} ${heat_proxy_cfn} admin http://${management_ip}/${heat_proxy_cfn}/v1", "openstack endpoint list | /bin/grep '${service}_cfn.*admin'" ],
    "create_domain_heat" => [ "openstack domain create --description 'Stack projects and users' ${service}", "openstack domain list | /bin/grep ${service}" ],
    "domain_heat_create_user" => [ "openstack user create --domain heat --password ${domain_admin_pass} ${domain_admin}", "openstack user list | /bin/grep ${domain_admin}" ],    
    "domain_heat_role_add_admin" => [ "openstack role add --domain heat --user-domain heat --user ${domain_admin} admin", "openstack role assignment list --names | /bin/grep ${domain_admin}@heat" ],
    "domain_heat_role_create_stack_owner" => [ "openstack role create heat_stack_owner", "openstack role list | /bin/grep heat_stack_owner" ],
    "domain_heat_role_add_stack_owner" => [ "openstack role add --project ${project} --user admin heat_stack_owner ", "openstack role assignment list --project ${project} --names | /bin/grep heat_stack_owner" ],
    "domain_heat_role_create_stack_user" => [ "openstack role create heat_stack_user", "openstack role list | /bin/grep heat_stack_user" ],
  }

  openstack::utils::bulkrun { 'setup_heat_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    Openstack::Utils::Website['enable_uwsgi_heat_api'],
                    Openstack::Utils::Website['enable_uwsgi_heat_api_cfn']]
  }

}
