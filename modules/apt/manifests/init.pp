class apt {

	# Update sources
	exec { "${title}_update":
		command => '/usr/bin/apt update',
	}

	# Always install packages with --no-install-recommends enabled
	$options = @(END)
	APT::Install-Recommends "0";
	APT::Install-Suggests "0";
	END
	
	file { '/etc/apt/apt.conf.d/01norecommend':
		ensure => present,
		owner => 'root',
		group => 'root',
		mode  => '0644',
		content => inline_epp($options)
	}


}
