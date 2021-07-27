class ntp {
  
	# gather ntp servers list from hiera
	$ntp = lookup('ntp', Hash)
	$timezone = $ntp['timezone']
  $servers = $ntp['servers']


	# install ntp
	package { 'ntp':
		ensure => installed,
	}

	# disable timesyncd
	exec { 'disable_timesyncd':
		command => "/usr/bin/timedatectl set-ntp no",
		user => 'root',
		group => 'root',
		unless => "/usr/bin/timedatectl | /bin/grep 'systemd-timesyncd.service active: no'",
	}

	# configure timezone
	exec { 'configure_timezone':
		command => "/usr/bin/timedatectl set-timezone ${timezone}",
		user => 'root',
		group => 'root',
		unless => "/usr/bin/timedatectl | /bin/grep ${timezone}",
	}

	# create config
	file { '/etc/ntp.conf':
		ensure => present,
		content => template('ntp/ntp.conf.erb'),
		require => Package['ntp'],
		notify => Service['ntp'],						# restart service on config change
	}

	# ensure service is running and enabled
	service { 'ntp':
		ensure => running,
		enable => true,
		require => Package['ntp'],
	}
}
