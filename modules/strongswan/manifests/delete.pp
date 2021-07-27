class strongswan::delete inherits haproxy {

  # stop and delete services
  service { $services:
    ensure => stopped,
    enable => false,
  }

  # delete configuration files
  file { ['/etc/strongswan.conf',
          '/etc/strongswan.d']:
    ensure => directory,
    purge => true,
    force => true,
    recurse => true,
  }

  # Remove a packages 
  package { $packages:
      ensure => 'purged',
  }

  # Remove already unneeded depencies and dowloaded apk
  apt::utils::apt_clean { 'clean_strongswan': }
  
}
