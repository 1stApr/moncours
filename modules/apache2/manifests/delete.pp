class apache2::delete inherits apache2 {

  # stop and delete services
  service { $services:
    ensure => stopped,
    enable => false,
  }

  # delete configuration files
  file { ['/etc/apache2',
          '/var/www']:
    ensure => absent,
    purge => true,
    force => true,
    recurse => true,
  }

  # Remove a packages and purge its config files
  package { [$packages,              
             $depencies]:
      ensure => 'purged',
  }

  # Remove already unneeded depencies and dowloaded apk
  apt::utils::apt_clean { 'clean_apache2': }
  
}
