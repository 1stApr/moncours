class prometheus::executor::install inherits prometheus::install {


	# local constant
  $service = 'prometheus-am-executor'


  # download executor binary
	exec { 'download_executor':
		command => "/usr/bin/wget https://github.com/thiagoalmeidasa/prometheus-am-executor/releases/download/v0.0.2/prometheus-am-executor \
             && /bin/chmod +x ${service_dir}/prometheus-am-executor",
    group => 'prometheus',
    user => 'prometheus',
		cwd => $service_dir,
		creates => "${service_dir}/prometheus-am-executor",
	}

  # create alarm firing script
	file { "${service_dir}/autoscaling.sh":
		ensure => present,
    group => 'prometheus',
    owner => 'prometheus',
    mode => '500',
		content => template('prometheus/autoscaling.sh.erb'),
		notify => Service[$service],
    require => Exec['download_executor']
	}

  # create service file
	file { "/lib/systemd/system/${service}.service":
		ensure => present,
		content => template('prometheus/service.erb'),
    require => File["${service_dir}/autoscaling.sh"]
	}

	# ensure service is running and enabled
	service { $service:
		ensure => running,
		enable => true,
		require => File["/lib/systemd/system/${service}.service"]
	}


}
