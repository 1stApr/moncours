# Configure logrotate options for OpenStack service
#
# @service   - OpenStack service name
# @threshold - how often rotate logs
# @keep      - how many logs to keep
# @depends   - requirements to run this function
#
define openstack::utils::logrotate (

    String $service, 
    String $threshold,
    Integer $keep,
    Any $depends
  
  ) {

  file { "/etc/logrotate.d/${service}":
    ensure => present,
    owner => 'root',
    group => 'root',
    content => "/var/log/openstack/${service}/*.log { 
  ${threshold}
  missingok
  rotate ${keep}
  notifempty
  nocreate
}

",
    require => $depends
  }

}



