class mariadb::delete inherits mariadb {

  # stop and delete services
  service { $services:
    ensure => stopped,
    enable => false,
  }

  # delete images, containers, volumes, or customized configuration files
  file { [$repository,
          '/etc/mysql',
          $home]:
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
  apt::utils::apt_clean { 'clean_mariadb': }
  
}
