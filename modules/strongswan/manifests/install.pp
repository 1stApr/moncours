class strongswan::install inherits strongswan {

  # install 
  package { $packages:
    ensure => installed
  }

  # stop and disable service
  service { $services:
    provider => 'systemd',
    ensure => stopped,
    enable => false,
    require => Package[$packages]
  }
  
}
