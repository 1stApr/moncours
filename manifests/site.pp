node default {

	# Use puppet stages to ensure that system preparation actions
	# take place in first time. Without relying on puppet automatic 
	# resource chaining mechanism
	# 
	stage { 'first':
		before => Stage['main']
	}

	class { 'apt': stage => first }
	class { 'network': stage => first }
	class { 'ntp': stage => first }
	class { 'ssh': stage => first }
	
	
	include diskimage_builder::install
	include haproxy::install
	include strongswan::install
	include memcached::install
	include mariadb::install
	include rabbitmq::install
	include apache2::install
	include prometheus::install
	include nfs::install

	
	include openstack::install

}

