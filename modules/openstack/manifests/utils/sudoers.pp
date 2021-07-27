# Create sudoers OpenStack service rules
#
# @service   - OpenStack service name
# @template  - optional: filter template
# @depends   - requirements to run this function
#
define openstack::utils::sudoers (

    String $service, 
    String $template,
    Any $depends

  ) {

  file { "/etc/sudoers.d/${service}":
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0440',
    content => $template,
    require => $depends
  }

}

