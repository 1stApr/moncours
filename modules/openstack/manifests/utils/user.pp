# Create service system user and required folders
#
# @service  - OpenStack service name
# @depends  - requirements to run this function
#
define openstack::utils::user(
  
    String $service,
    Any $depends

  ) {

  # create system service account
  user { $service:
    ensure => present,
    home => "/var/lib/openstack/${service}",
    managehome => true,
    shell => '/bin/false',
    system => true,
    require => $depends
  }

  # create service additional directories
  file { ["/var/log/openstack/${service}",
          "/etc/${service}",
          "/etc/${service}/rootwrap.d",
          "/var/lib/openstack/${service}/tmp"]:
    ensure => 'directory',
    owner => $service,
    group => $service,
    require => User[$service]
  }

  if $service == "neutron" {
    file { ['/etc/neutron/plugins',
            '/etc/neutron/plugins/ml2']:
      ensure => 'directory',
      owner => $service,
      group => $service,
      require => File["/etc/${service}"]
    }
  }
  
  if $service == "nova" {
    file { '/var/lib/openstack/nova/instances' :
      ensure => 'directory',
      owner => $service,
      group => $service,
      recurse => true,
      require => File["/etc/${service}"]
    }
  }

}

