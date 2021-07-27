class prometheus::alertmanager::install inherits prometheus::install {


	# local constant
  $service = 'prometheus-alertmanager'


  # download alertmanager binary
	exec { 'download_alertmanager':
		command => "/usr/bin/wget https://github.com/prometheus/alertmanager/releases/download/v${alert_version}/alertmanager-${alert_version}.linux-amd64.tar.gz",
		cwd => $service_dir,
		creates => "${service_dir}/alertmanager-${alert_version}.linux-amd64.tar.gz",
	}

	# unpack
	exec { 'unpack_alertmanager':
		command => "/bin/tar xf alertmanager-${alert_version}.linux-amd64.tar.gz --strip 1",
		cwd => $service_dir,
    creates => "${service_dir}/alertmanager",
		require => Exec['download_alertmanager']
	}

  # create config
	file { "${config_dir}/alertmanager.yaml":
		ensure => present,
		content => template('prometheus/alertmanager.yaml.erb'),
		notify => Service[$service],
    require => File[$config_dir],
	}

  # create service file
	file { "/lib/systemd/system/${service}.service":
		ensure => present,
		content => template('prometheus/service.erb'),
    require => Exec['unpack_alertmanager']
	}

	# ensure service is running and enabled
	service { $service:
		ensure => running,
		enable => true,
		require => [File["/lib/systemd/system/${service}.service"],
                File["${config_dir}/alertmanager.yaml"]]
	}


}
