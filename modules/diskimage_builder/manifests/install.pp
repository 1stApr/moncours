class diskimage_builder::install inherits diskimage_builder {

  # check if it not already defined and install depencies
  $depencies.each|$dep| {
    if !defined(Package[$dep]) {
      package { $dep:
        ensure => installed,
      }
    }
  }

  # install 
  exec { 'install_diskimage_builder':
    command => "/usr/bin/pip3 install diskimage-builder", 
    user => 'root',
    group => 'root',    
    creates => '/usr/local/bin/disk-image-create',
    require => Package[$depencies]
  }

}

