# nova cells: https://docs.openstack.org/nova/train/user/cellsv2-layout.html
#             https://docs.openstack.org/nova/latest/user/cells.html
#             https://docs.openstack.org/nova/latest/cli/nova-manage.html
#
class openstack::nova::install inherits openstack::install {


  # current module local constants
  #
  # /etc/nova/nova.conf                       
  # /etc/nova/nova-compute.conf               
  # /etc/nova/nova-cell1.conf                 
  # /etc/nova/api-paste.ini   
  # /etc/nova/rootwrap.conf
  #
  $configs = ['nova.conf', 'nova-compute.conf', 'nova-cell1.conf',
              'api-paste.ini', 'rootwrap.conf']

  #       nova-api                   - nova.conf
  #       nova-metadata              - nova-cell1.conf
  #       nova-conductor-cell1       - nova-cell1.conf
  #       nova-conductor             - nova.conf                    # super conductor
  #       nova-compute               - nova-compute.conf
  #       nova-spicehtml5proxy       - nova-cell1.conf
  #       nova-scheduler             - nova.conf
  $system_services = ['nova-api', 'nova-metadata', 'nova-conductor-cell1', 'nova-conductor',
                      'nova-compute', 'nova-spicehtml5proxy', 'nova-scheduler']

  # nova rootwrap filters
  $filters = ['api-metadata.filters', 'compute.filters', 'network.filters']


  # setup nova prerequisites
  openstack::utils::prerequisites { 'nova_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    filters         => $filters,
    sudoers         => template('openstack/nova/nova.sudoers.erb'),
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/nova-manage',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # install hypervisor and remoute console
  if $hypervisor == 'kvm' {

    class {'openstack::kvm::install':
      depends  => Openstack::Utils::Prerequisites['nova_prerequisites']
    }
  }

  if $console == 'spice-html5' {
    include openstack::spice_html5::install
  }


  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "nova_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['nova_prerequisites']
    }
  }

  # /etc/nova/uwsgi-nova-api.ini              
  openstack::utils::uwsgi { 'uwsgi_nova_api':
    service => $service,
    unit    => 'nova-api',
    port    => $nova_port,
    reload  => Service[$system_services],
    depends => File['/etc/nova/nova.conf']
  }  
  
  # create rabbitmq channel and grant permissions for cell1
  rabbitmq::utils::create_channel { 'create_channel_nova_cell1':
    user => $service,
    channel => 'nova_cell1',
    depends => File['/etc/nova/nova.conf']
  }

  # generate policy
  openstack::utils::policy { 'nova_policy':
    service => $service,
    config  => '/etc/nova/nova.conf',
    depends => File['/etc/nova/nova.conf']
  }

  # create cells databases
  openstack::utils::database { 'create_database_nova_api':
    dbname          => 'nova_api',
    dbrootpassword  => $dbrootpassword,
    dbuser          => $service,
    dbpass          => $password,
    depends         => Openstack::Utils::Prerequisites['nova_prerequisites']
  }

  openstack::utils::database { 'create_database_nova_cell0':
    dbname          => 'nova_cell0',
    dbrootpassword  => $dbrootpassword,
    dbuser          => $service,
    dbpass          => $password,
    depends         => Openstack::Utils::Prerequisites['nova_prerequisites']
  }

  openstack::utils::database { 'create_database_nova_cell1':
    dbname          => 'nova_cell1',
    dbrootpassword  => $dbrootpassword,
    dbuser          => $service,
    dbpass          => $password,
    depends         => Openstack::Utils::Prerequisites['nova_prerequisites']
  }

  # populate nova databases
  exec { "populate_database_${service}":
    command => "/usr/local/bin/nova-manage --config-file /etc/nova/nova.conf api_db sync \
             && /usr/local/bin/nova-manage cell_v2 map_cell0 --database_connection 'mysql+pymysql://${service}:${password}@${dbhost}/nova_cell0?charset=utf8' \
             && /usr/local/bin/nova-manage --config-file /etc/nova/nova-cell1.conf db sync --local_cell \
             && /usr/local/bin/nova-manage --config-file /etc/nova/nova.conf db sync \
             && /usr/local/bin/nova-manage --config-file /etc/nova/nova.conf db online_data_migrations \
             && /usr/local/bin/nova-manage --config-file /etc/nova/nova.conf --config-file /etc/nova/nova-cell1.conf cell_v2 create_cell --name=cell1 \
             && /usr/local/bin/nova-manage cell_v2 discover_hosts",
    user => $service,
    group => $service,
    provider => 'shell',
    timeout => 900,
    require => [Openstack::Utils::Prerequisites['nova_prerequisites'],
                Openstack::Utils::Database['create_database_nova_api'],
                Openstack::Utils::Database['create_database_nova_cell0'],
                Openstack::Utils::Database['create_database_nova_cell1'],
                Openstack::Utils::Uwsgi['uwsgi_nova_api']],
    unless => "/usr/bin/mariadb -u ${service} \
                                -p${password} \
                                -e 'select host from host_mappings;' nova_api | /bin/grep ${host}"        
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Exec["populate_database_${service}"]
    }
  }

  # create nova-api apache site config
  openstack::utils::website { 'enable_uwsgi_nova_api':
    site     => 'uwsgi-nova-api',
    service  => $service,
    port     => $nova_port,
    proxy    => $nova_proxy,
    depends  => Service[$system_services]
  }

  # openstack user create --domain default --password ${password} nova
  # openstack role add --project service --user nova admin
  # openstack service create --name ${service} --description "OpenStack Compute" compute
  # openstack service create --name ${service}_legacy --description "OpenStack Compute" compute_legacy
  # openstack endpoint create --region ${region} compute public http://${management_ip}/compute/v2.1
  # openstack endpoint create --region ${region} compute admin http://${management_ip}/compute/v2.1
  # openstack endpoint create --region ${region} compute_legacy public http://${management_ip}/compute/v2/%\(project_id\)s
  # openstack endpoint create --region ${region} compute_legacy admin http://${management_ip}/compute/v2/%\(project_id\)s
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
    "openstack_create_service_${service}" => [ "openstack service create --name ${service} --description 'OpenStack Compute' ${nova_proxy}", "openstack service list | /bin/grep ${nova_proxy}" ],
    "openstack_create_service_${service}_legacy" => [ "openstack service create --name ${service}_legacy --description 'OpenStack Compute' ${nova_proxy}_legacy", "openstack service list | /bin/grep ${nova_proxy}_legacy" ],
    "openstack_create_endpoint_public_${service}" => [ "openstack endpoint create --region ${region} ${nova_proxy} public http://${management_ip}/${nova_proxy}/v2.1", "openstack endpoint list | /bin/grep '${nova_proxy}.*public'" ],
    "openstack_create_endpoint_admin_${service}" => [ "openstack endpoint create --region ${region} ${nova_proxy} admin http://${management_ip}/${nova_proxy}/v2.1", "openstack endpoint list | /bin/grep '${nova_proxy}.*admin'" ],
    "openstack_create_endpoint_public_${service}_legacy" => [ "openstack endpoint create --region ${region} ${nova_proxy}_legacy public http://${management_ip}/${nova_proxy}/v2/%\\(project_id\\)s", "openstack endpoint list | /bin/grep '${nova_proxy}_legacy.*public'" ],
    "openstack_create_endpoint_admin_${service}_legacy" => [ "openstack endpoint create --region ${region} ${nova_proxy}_legacy admin http://${management_ip}/${nova_proxy}/v2/%\\(project_id\\)s", "openstack endpoint list | /bin/grep '${nova_proxy}_legacy.*admin'" ],
  }

  openstack::utils::bulkrun { 'setup_nova_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    Openstack::Utils::Website['enable_uwsgi_nova_api']]
  }


}
