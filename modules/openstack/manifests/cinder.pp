# NFS storage backend: https://docs.openstack.org/cinder/train/admin/blockstorage-nfs-backend.html
#
class openstack::cinder::install inherits openstack::install {


  # current module local constants
  #
  # /etc/cinder/cinder.conf                       
  # /etc/cinder/api-paste.ini   
  # /etc/cinder/rootwrap.conf
  #
  $configs = ['cinder.conf', 'api-paste.ini', 'rootwrap.conf']

  # cinder-api          - controller node
  # cinder-volume
  # cinder-scheduler    - controller node
  # cinder-backup
  $system_services = ['cinder-api', 'cinder-scheduler', 'cinder-volume', 'cinder-backup']

  # cinder rootwrap filters
  $filters = ['volume.filters']


  # setup cinder prerequisites
  openstack::utils::prerequisites { 'cinder_prerequisites':
    service         => $service,
    password        => $password,
    release         => $release,
    root            => $root,
    filters         => $filters,
    sudoers         => template('openstack/cinder/cinder.sudoers.erb'),
    dbrootpassword  => $dbrootpassword,
    creates         => '/usr/local/bin/cinder-manage',
    threshold       => $logthreshold,
    keep            => $logkeep
  }

  # setup nfs backend parameters
  if $nfs != undef {
    
    $volume = $nfs['volume']
    $backup = $nfs['backup']

    file { '/etc/cinder/nfs_shares':
      ensure => present,
      owner => $service,
      group => $service,
      content => template("openstack/cinder/nfs_shares.erb"),
      notify => Service[$system_services],
      require => Openstack::Utils::Prerequisites['cinder_prerequisites'],
      before =>  Openstack::Utils::Database::Populate['populate_cinder_database']
    }

    nfs::utils::add_export { "add_volume_export_${service}":
      host => $management_ip,
      folder => $volume,
      owner => $service
    }

    nfs::utils::add_export { "add_backup_export_${service}":
      host => $management_ip,
      folder => $backup,
      owner => $service
    }
  }

  # create configuration files
  $configs.each |$config| {
    
    openstack::utils::config { "cinder_config_${config}":
      service  => $service,
      config   => $config,
      template => template("openstack/${service}/${config}.erb"),
      reload   => Service[$system_services],
      depends  => Openstack::Utils::Prerequisites['cinder_prerequisites']
    }
  }

  # /etc/cinder/uwsgi-cinder-api.ini              
  openstack::utils::uwsgi { 'uwsgi_cinder_api':
    service => $service,
    unit    => 'cinder-api',
    port    => $cinder_port,
    reload  => Service[$system_services],
    depends => File['/etc/cinder/cinder.conf']
  }

  # generate policy
  openstack::utils::policy { 'cinder_policy':
    service => $service,
    config  => '/etc/cinder/cinder.conf',
    depends => File['/etc/cinder/cinder.conf']
  }

  # populate cinder database
  openstack::utils::database::populate { 'populate_cinder_database':
    service  => $service,
    password => $password,
    command  => '/usr/local/bin/cinder-manage db sync',
    table    => 'volumes',
    depends  => Openstack::Utils::Uwsgi['uwsgi_cinder_api']
  }

  # setup system services 
  $system_services.each |$unit| {
    
    openstack::utils::service { "setup_system_service_${unit}":
      service  => $service,
      unit     => $unit,
      depends  => Openstack::Utils::Database::Populate['populate_cinder_database']
    }
  }

  # create cinder-api apache site config
  openstack::utils::website { 'enable_uwsgi_cinder_api':
    site     => 'uwsgi-cinder-api',
    service  => $service,
    port     => $cinder_port,
    proxy    => $cinder_proxy,
    depends  => Service[$system_services]
  }

  # openstack user create --domain default --password ${password} cinder
  # openstack role add --project service --user cinder admin
  # openstack service create --name ${service}v3 --description "OpenStack Block Storage" volumev3
  # openstack service create --name ${service} --description "OpenStack Block Storage" block-storage
  # openstack endpoint create --region ${region} volumev3 public http://${management_ip}/volume/v3/%\(project_id\)s
  # openstack endpoint create --region ${region} volumev3 admin http://${management_ip}/volume/v3/%\(project_id\)s
  # openstack endpoint create --region ${region} block-storage public http://${management_ip}/volume/v3/%\(project_id\)s
  # openstack endpoint create --region ${region} block-storage admin http://${management_ip}/volume/v3/%\(project_id\)s
  #
  $commands = {
    "openstack_create_user_${service}" => [ "openstack user create --domain default --password ${password} ${service}", "openstack user list | /bin/grep ${service}" ],
    "openstack_create_role_${service}" => [ "openstack role add --project service --user ${service} admin", "openstack role assignment list --user ${service} --project service --names | /bin/grep admin" ],
    "openstack_create_service_${service}_v3" => [ "openstack service create --name ${service}v3 --description 'OpenStack Block Storage' ${cinder_proxy}v3", "openstack service list | /bin/grep ${cinder_proxy}v3" ],
    "openstack_create_service_${service}_block" => [ "openstack service create --name ${service} --description 'OpenStack Block Storage' block-storage", "openstack service list | /bin/grep block-storage" ],
    "openstack_create_endpoint_public_${service}_v3" => [ "openstack endpoint create --region ${region} ${cinder_proxy}v3 public http://${management_ip}/${cinder_proxy}/v3/%\\(project_id\\)s", "openstack endpoint list | /bin/grep '${cinder_proxy}v3.*public'" ],
    "openstack_create_endpoint_admin_${service}_v3" => [ "openstack endpoint create --region ${region} ${cinder_proxy}v3 admin http://${management_ip}/${cinder_proxy}/v3/%\\(project_id\\)s", "openstack endpoint list | /bin/grep '${cinder_proxy}v3.*admin'" ],
    "openstack_create_endpoint_public_${service}_block" => [ "openstack endpoint create --region ${region} block-storage public http://${management_ip}/${cinder_proxy}/v3/%\\(project_id\\)s", "openstack endpoint list | /bin/grep 'block-storage.*public'" ],
    "openstack_create_endpoint_admin_${service}_block" => [ "openstack endpoint create --region ${region} block-storage admin http://${management_ip}/${cinder_proxy}/v3/%\\(project_id\\)s", "openstack endpoint list | /bin/grep 'block-storage.*admin'" ],
  }

  openstack::utils::bulkrun { 'setup_cinder_credentials':
    commands    => $commands,
    environment => $environment,
    depends     => [Class['Openstack::Keystone::Install'],
                    Openstack::Utils::Website['enable_uwsgi_cinder_api']]
  }

  # add volume type
  if $nfs != undef {

    $types = { 
      'create_cinder_volume_type_nfs' => ["openstack volume type create nfs --public --description 'NFS volumes'", "openstack volume type list | /bin/grep -w nfs.*True"] 
    }

    openstack::utils::bulkrun { 'setup_cinder_volumes_types':
      commands    => $types,
      environment => $environment,
      depends     => Openstack::Utils::Bulkrun['setup_cinder_credentials']
    }

  }

}
