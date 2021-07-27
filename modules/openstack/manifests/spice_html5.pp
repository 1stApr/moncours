class openstack::spice_html5::install inherits openstack::install {

  package { 'spice-html5':
        ensure => 'installed'
  }

}
