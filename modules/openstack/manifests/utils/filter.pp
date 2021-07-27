# Create filter config file from template in /etc/$service/rootwrap.d folder
#
# @service   - OpenStack service name
# @filter    - filter file name
# @depends   - requirements to run this function
#
define openstack::utils::filter (

    String $service, 
    String $filter,
    Any $depends

  ) {

  file { "/etc/${service}/rootwrap.d/${filter}":
    ensure => present,
    owner => $service,
    group => $service,
    content => template("openstack/${service}/rootwrap.d/${filter}"),
    require => $depends
  }

}

