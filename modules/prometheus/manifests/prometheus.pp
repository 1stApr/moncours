class prometheus::prometheus::install inherits prometheus::install {


	# local constant
  $service = 'prometheus'


  # download prometheus binary
	exec { 'download_prometheus':
		command => "/usr/bin/wget https://github.com/prometheus/prometheus/releases/download/v${version}/prometheus-${version}.linux-amd64.tar.gz",
		cwd => $service_dir,
		creates => "${service_dir}/prometheus-${version}.linux-amd64.tar.gz",
	}

	# unpack
	exec { 'unpack_prometheus':
		command => "/bin/tar xf prometheus-${version}.linux-amd64.tar.gz --strip 1",
		cwd => $service_dir,
    creates => "${service_dir}/prometheus",
		require => Exec['download_prometheus']
	}

  # create config
	file { "${config_dir}/prometheus.yaml":
		ensure => present,
		content => template('prometheus/prometheus.yaml.erb'),
		notify => Service[$service],
    require => File[$config_dir],
	}

  # create alert rules file
	file { "${config_dir}/alert_rules.yaml":
		ensure => present,
		content => template('prometheus/alert_rules.yaml.erb'),
		notify => Service[$service],
    require => File[$config_dir],
	}

  # create service file
	file { "/lib/systemd/system/${service}.service":
		ensure => present,
		content => template('prometheus/service.erb'),
    require => Exec['unpack_prometheus']
	}

	# ensure service is running and enabled
	service { $service:
		ensure => running,
		enable => true,
		require => [File["/lib/systemd/system/${service}.service"],
                File["${config_dir}/prometheus.yaml"]]
	}

}


