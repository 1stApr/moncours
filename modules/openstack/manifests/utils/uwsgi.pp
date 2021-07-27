# Create uwsgi.ini file
# Configuration file template located in module root templates directory ('openstack/uwsgi.erb')
# Template gets $unit variable with service name in it
# and over multiple 'if' statements choose parameters to write to config file
#
# @service   - OpenStack service name
# @unit      - system service name
# @port      - port to listen by uwsgi server
# @listen    - ip address of interface to listen on
# @reload    - service or event altered to reload
# @depends   - requirements to run this function
#
define openstack::utils::uwsgi (

    String $service, 
    String $unit,
    Integer $port,
    Optional[String] $listen = '127.0.0.1',
    Any $reload,
    Any $depends

  ) {

  file { "/etc/${service}/uwsgi-${unit}.ini":
    ensure => present,
    owner => $service,
    group => $service,
    content => template('openstack/uwsgi.erb'),
    notify => $reload,
    require => $depends
  }

}

