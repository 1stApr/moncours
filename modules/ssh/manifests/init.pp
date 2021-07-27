class ssh {

  $config = '/etc/ssh/sshd_config'
  $context = "/files/${config}"


	# install openssh-server
	package { 'openssh-server':
		ensure => installed,
	}

  # set parameter with augeas tool
  augeas { 'add_ssh_server_keepalive':
    context => $context,
    changes => [ "set ClientAliveInterval 120" ],
    onlyif  => "get ClientAliveInterval != 120",
		notify  => Service['ssh']
  }

	# ensure service is running and enabled
	service { 'ssh':
		ensure => running,
		enable => true,
		require => Package['openssh-server'],
	}
}
