class prometheus::delete inherits prometheus {

  # stop and delete services
  service { $services:
    ensure => stopped,
    enable => false,
  }

  # delete user and group
  group { 'prometheus' :
    ensure => 'absent'
  }

	user { 'prometheus':
 		ensure => 'absent',
    require => Group['prometheus']
	}

  # delete directories and files
  file { [$service_dir,
          $config_dir,
          $data_dir]:
    ensure => absent,
    purge => true,
    force => true,
    recurse => true,
  }

  # Remove already unneeded depencies and dowloaded apk
  apt::utils::apt_clean { 'clean_prometheus': }
  
}
