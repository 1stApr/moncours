class nfs::install inherits nfs {

  
  # install nfs server
  package { $packages:
    ensure => installed
  }

  # ensure root export folder exists
  file { $root:
    ensure => 'directory',
    owner => 'root',
    group => 'root',
    require => Package[$packages]
  }

  # ensure service is running and enabled
	service { $services:
		ensure => running,
		enable => true,
    require => File[$root]
	}

}
