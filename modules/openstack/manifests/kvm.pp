#
class openstack::kvm::install (

  Any $depends

)inherits openstack::install {


  $packages = ['qemu-kvm', 'libvirt-bin', 'python3-libvirt']

  # install packages 
  package { $packages:
    ensure => installed,
  }

  # ensure service is running and enabled
	service { 'libvirt-bin':
		ensure => running,
		enable => true,
		require => Package[$packages]
	}

  # add user nova to libvirt group
  exec { 'add_nova_libvirt_group':
    command => '/usr/sbin/usermod -a -G libvirt nova',
    user => 'root',
    group => 'root',
    require => [Service['libvirt-bin'],
                $depends],
    unless => '/usr/bin/groups nova | /bin/grep libvirt'
  }

  # disable default libvirt network
  # https://docs.openstack.org/neutron/train/admin/misc-libvirt.html
  exec { 'disable_libvirt_network':
    command => '/usr/bin/virsh net-destroy default \
             && /usr/bin/virsh net-autostart --network default --disable',
    user => 'root',
    group => 'root',
    require => Service['libvirt-bin'],
    onlyif => "/usr/bin/virsh net-list | /bin/grep 'default.*active'"
  }
             
}
