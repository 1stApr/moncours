class rabbitmq::delete inherits rabbitmq {


  # stop and delete services
  service { $services:
    ensure => stopped,
    enable => false,
  }

  # Remove a packages and purge its config files
  package { [$packages,
             $depencies]:
      ensure => 'purged',
  }

  # Remove already unneeded depencies and dowloaded apk
  apt::utils::apt_clean { 'clean_rabbitmq': }

}
