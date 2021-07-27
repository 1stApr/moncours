class openstack::horizon::install inherits openstack::install {

  # local variables
  $webroot = "${service_dir}/${service}"
  $config = "${webroot}/openstack_dashboard/local/local_settings.py"


  # clone repository
  openstack::utils::git::clone { 'clone_repository_horizon':
    release => $release,
    service => $service,
    root    => $root,
  }

  # create system user and required folders
  openstack::utils::user { 'create_user_horizon':
    service => $service,
    depends => Openstack::Utils::Git::Clone['clone_repository_horizon']
  }

  # install python requirements
  # note: constraints limitation of max versions of packages
  openstack::utils::python::requirements { 'install_python_requirements_horizon':
    service     => $service,
    release     => $release,
    home        => $root,
    depends     => Openstack::Utils::User['create_user_horizon']
  }

  # setup
  openstack::utils::python::setup { 'setup_horizon':
    service => $service,
    home    => "${root}/${service}",
    creates => "${webroot}/openstack_dashboard/wsgi.py",
    depends => Openstack::Utils::Python::Requirements['install_python_requirements_horizon']
  }

  # create blackhole folder
  file { "${webroot}/.blackhole":
    ensure => 'directory',
    owner => $service,
    group => $service,
    require => Openstack::Utils::Python::Setup['setup_horizon']
  }

  # copy static resources
  exec { "django_collectstatic_${service}":
    command => "/usr/bin/python3.6 manage.py collectstatic --noinput \
             && /usr/bin/touch ${root}/${service}/collectstatic.done",
    provider => 'shell',
    cwd => "${root}/${service}",
    creates => "${root}/${service}/collectstatic.done",
    environment => "DJANGO_SETTINGS_MODULE=openstack_dashboard.settings",
    require => Openstack::Utils::Python::Setup['setup_horizon']
  }

  # copy dashboard
  # used rsync because cp doesn't have option to exclude some files
  exec { "copy_dashboard_${service}":
    command => "/usr/bin/rsync -r -a -v --exclude \".*\" ${root}/${service}/openstack_dashboard ${root}/${service}/static ${webroot}",
    user => $service,
    group => $service,
    cwd => $webroot,
    require => Exec["django_collectstatic_${service}"],
    creates => "${webroot}/openstack_dashboard/wsgi.py"
  }

  # create config
  file { $config:
    ensure => present,
    owner => $service,
    group => $service,
    content => template('openstack/horizon/local_settings.py.erb'),
    notify => Exec['reload_apache_dashboard'],
    require => Exec["copy_dashboard_${service}"]
  }

  # restart apache by notification only if configuration changed 
  exec { 'reload_apache_dashboard':
    command => '/usr/sbin/service apache2 restart',
    user => 'root',
    group => 'root',
    refreshonly => 'true'
  }

  # create dashboard apache site config
  openstack::utils::website { 'enable_horizon_website':
    site        => 'horizon',
    service     => $service,
    port        => $horizon_port,
    proxy       => $horizon_proxy,
    service_dir => $service_dir,
    template    => 'openstack/horizon/horizon.conf.erb',
    depends     => File[$config]
  }

  # plugins installation
  $plugins.each |$plugin, $value| {

    openstack::utils::dashboard::plugin { "${plugin}_plugin_install":
      plugin            => $plugin,
      release           => $release,
      root              => $root,
      dashboard         => "${service_dir}/${service}/openstack_dashboard",
      check             => $value['check'],
      settings          => $value['settings'],
      settings_template => template("openstack/horizon/plugins/${plugin}.erb"),
      policy_template   => template("openstack/horizon/plugins/${plugin}.json")
    }
  }

}
