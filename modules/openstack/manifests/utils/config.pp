# Create config file from template in /etc/$service folder
#
# @service   - OpenStack service name
# @config    - configuration file name
# @template  - configuration file template
# @reload    - service or event altered to reload
# @depends   - requirements to run this function
#
define openstack::utils::config (

    String $service, 
    String $config,
    String $template,
    Any $reload,
    Any $depends

  ) {

  file { "/etc/${service}/${config}":
    ensure => present,
    owner => $service,
    group => $service,
    content => $template,
    notify => $reload,
    require => $depends
  }

}

