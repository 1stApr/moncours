class openstack::install inherits openstack {



  # check if it not already defined and install depencies
  $depencies.each|$dep| {
    if !defined(Package[$dep]) {
      package { $dep:
        ensure => 'installed',
      }
    }
  }

  # install uwsgi server 
  exec { 'install_uwsgi':
    command => "/usr/bin/pip3 install uwsgi",
    user => 'root',
    group => 'root',
    provider => 'shell',
    require => Package[$depencies],
    creates => '/usr/local/bin/uwsgi'
  }

  # install openstack client 
  exec { 'install_openstackclient':
    command => "/usr/bin/pip3 install openstackclient \
                                -c https://opendev.org/openstack/requirements/raw/branch/${release}/upper-constraints.txt", 
    user => 'root',
    group => 'root',
    provider => 'shell',
    require => Package[$depencies],
    creates => '/usr/local/bin/openstack'
  }

  # create openstack home and other directories
  file { [$root,
          $logs_dir,
          $service_dir]:
    ensure => 'directory',
    owner => 'root',
    group => 'root',
    require => Exec['install_openstackclient']
  }
  

  # run declared services setup
  $services.keys().each|$service| {

    include "openstack::${service}::install"
  
  }

}
