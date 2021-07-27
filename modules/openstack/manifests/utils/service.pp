# Create and run system service
# Service file template located in module root templates directory ('openstack/serrvice.erb')
# Template gets $unit variable with service name in it
# and over multiple 'if' statements choose commands to write to service file
#
# @service   - OpenStack service name
# @unit      - system service name
# @depends   - requirements to run this function
#
define openstack::utils::service (

    String $service, 
    String $unit,
    Any $depends

  ) {

  # create systemd services
  file { "/lib/systemd/system/${unit}.service":
    ensure => present,
    owner => $service,
    group => $service,
    content => template('openstack/service.erb'),
    notify => Service[$unit],  
    require => $depends
  }

  # run service
  service { $unit:
    provider => 'systemd',
    ensure => running,
    enable => true,
    require => File["/lib/systemd/system/${unit}.service"]
  }

}

