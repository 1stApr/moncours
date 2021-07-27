class prometheus::install inherits prometheus {


  # check if it not already defined and install depencies
  $depencies.each|$dep| {
    if !defined(Package[$dep]) {
      package { $dep:
        ensure => installed,
      }
    }
  }

  # create prometheus system user and group
  group { 'prometheus' :
    ensure => 'present',
    require => Package[$depencies]
  }

	user { 'prometheus':
 		ensure => 'present',
    groups => 'prometheus',
		home => $service_dir,
		comment => 'Prometheus monitoring system user',
		system => true,
		managehome => true,
    require => Group['prometheus']
	}

  # create service directories
  file { [$data_dir,
          $config_dir]:
		ensure => 'directory',
		owner => 'prometheus',
		group => 'prometheus',
		recurse => true,
		require => User['prometheus']
	}

	# install prometheus
	include prometheus::prometheus::install

	# install alertmanager if defined
	if $prometheus['alertmanager'] {
		include prometheus::alertmanager::install
		include prometheus::executor::install
	}

}
