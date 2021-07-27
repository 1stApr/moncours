# create APT repository by creting repo file manually
# @key - Key ID or http:// link to key
# @file - repository file in /etc/apt/sources.list.d/
# @repository - content of repository file
#

define apt::utils::apt_repository($key = undef, String $file, String $repository) {

	# Test key value
	case $key {
		# http link
		/^http+/: {
				$command = "/usr/bin/wget -qO - ${key} | apt-key add -"
		}
		# key ID
		/^[A-Z0-9]+/: {
				$command = "/usr/bin/apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ${key}"
		}
	}

	# Check if key passed
	if $command != undef {
		exec { "${title}_key_install":
			command => $command,
			cwd => '/tmp',
			unless => "/usr/bin/test -f ${file}",		# Check if repository file already exists and don't run exec tasks if it true
		}
	}

	# create repository
	# echo "$repository" | sudo tee -a $file
	file { $file:
		ensure => present,
		owner => 'root',
		group => 'root',
		mode  => '0644',
		replace => 'false',
		content => $repository,
		notify => Exec["${title}_apt_update"],
	}

	exec { "${title}_apt_update":
		command => '/usr/bin/apt update',
		require => File[$file],
		refreshonly => true,
	}
}


# create APT repository by downloading and installing deb package
# @deb -
# @package -
# @fullname -
#
define apt::utils::apt_repository_deb (String $deb, String $package, String $fullname) {

	# download repo deb package
	exec { "${title}_download_deb":
		command => "/usr/bin/wget ${deb}",
		cwd => '/tmp',
		creates => "/tmp/${package}",
		unless => "/usr/bin/apt-cache show ${fullname}",  		# Check if repository deb package already installed and don't run exec tasks if it true
	}

	package { $package:
		ensure => installed,
		provider => 'dpkg',
		source => "/tmp/${package}",
		require => Exec["${title}_download_deb"],
	}

	exec { "${title}_apt_update":
		command => '/usr/bin/apt update',
		require => Package[$package],
	}
}

# Remove unneeded depencies and delete downloaded packages
define apt::utils::apt_clean {

	exec { "${title}_remove":
		command => '/usr/bin/apt autoremove -y',
	}

	exec { "${title}_clean":
		command => '/usr/bin/apt autoclean -y',
	}
}


# Update sources
define apt::utils::apt_update {
	
	exec { "${title}_update":
		command => '/usr/bin/apt update',
	}
}


