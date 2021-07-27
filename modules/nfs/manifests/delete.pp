class nfs::delete inherits nfs {

  # stop and delete services
  service { $services:
    ensure => stopped,
    enable => false,
  }

  # delete configuration files
  # but leave exported folder untouched
  file { $config:
    ensure => absent,
    purge => true,
    force => true,
    recurse => true,
  }

  # Remove a packages and purge its config files
  package { $packages]:
      ensure => 'purged',
  }

  # Remove already unneeded depencies and dowloaded apk
  apt::utils::apt_clean { 'clean_nfs': }
  
}
