class memcached::install inherits memcached {

  # install 
  package { $packages:
    ensure => installed
  }

  # create config
  file { '/etc/memcached.conf':
    ensure => present,
    content => "-l ${bind_address} -u memcache",
    require => Package[$packages],
    notify => Service[$services]
  }

  # ensure memcached service running and enabled
  service { $services:
    provider => 'systemd',
    ensure => running,
    enable => true,
    require => File['/etc/memcached.conf']
  }
  
}
