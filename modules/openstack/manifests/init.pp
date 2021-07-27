class openstack {

  $depencies = [ 'software-properties-common',
                 'git',
                 'wget',
                 'zip',
                 'libssl-dev',
                 'libffi-dev',
                 'ebtables',
                 'ipset',
                 'dnsmasq-utils',
                 'genisoimage',
                 'python3',
                 'python3-memcache',
                 'python3-pymysql',
                 'python3-pip',
                 'libpcre3-dev']

  $ntp = lookup('ntp', Hash)
  $timezone = $ntp['timezone']

  $db = lookup('mariadb', Hash)
  $dbhost = resolv($db['bind_address'])
  $dbrootpassword = $db['password']

  $memcached = lookup('memcached', Hash)
  $memcached_ip = $memcached['bind_address']

  $rabbitmq = lookup('rabbitmq', Hash)
  $rabbitmq_ip = $rabbitmq['bind_address']


  $host = $hostname
  $dns = lookup('dns', String)


  $openstack = lookup('openstack', Hash)
  $release = $openstack['release']
  $root = $openstack['root']
  $credentials_file = $openstack['credentials']
  $services = $openstack['services']
  $region = $openstack['region']
  $domain = $openstack['domain']
  $project = $openstack['project']
  $management_ip = $openstack['management_ip']
  $management_interface = getifname($management_ip)
  $public_ip = $openstack['public_ip']
  $public_interface = getifname($public_ip)
  $password = $openstack['password']
  $metadata_secret = $openstack['metadata_secret']
  $logs_dir = $openstack['logs_dir']
  $service_dir = $openstack['service_dir']

  # get main interface name and set network isolation type flag
  case $public_interface[0,2] {
    'vl': { $network_type = 'vlan' }
    'br': { $network_type = 'bridge' }
    default: { $network_type = 'unknown' }
  }

  # administrative account environment variables
  $environment = ["OS_USERNAME=admin",
                  "OS_PASSWORD=${password}",
                  "OS_REGION_NAME=${region}",
                  "OS_PROJECT_NAME=${project}",
                  "OS_USER_DOMAIN_NAME=Default",
                  "OS_PROJECT_DOMAIN_NAME=Default",
                  "OS_AUTH_URL=http://${management_ip}/identity",
                  "OS_IDENTITY_API_VERSION=3", 
                  "OS_AUTH_TYPE=password",
                  "PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" ]


  # logrotate options
  $logrotate = $openstack['logrotate']
  $logthreshold = $logrotate['threshold']
  $logkeep = $logrotate['keep']

  # because this is testing environment:
  #
  # service user name == service name
  # service password == $password
  #

  # Mandatory services
  $keystone = $services['keystone']
  $keystone_port = 5000
  $keystone_port_admin = 5358
  $keystone_proxy = 'identity'

  $glance = $services['glance']
  $glance_port = 9292
  $glance_proxy = 'image'
  $image_store = "${service_dir}/glance/images"     # directory where glance store images
  $image_download_dir = "${root}/glance/images"     # directory where images are downloaded before import in glance
  $glance_images = $glance['images']                # OS images to download

  $cinder = $services['cinder']
  $cinder_port = 8776
  $cinder_proxy = 'volume'
  $nfs = $cinder['nfs']

  $neutron = $services['neutron']
  $neutron_port = 9696
  $neutron_proxy = 'network'
  $kernel_modules = $neutron['kernel_modules']
  $neutron_provider = $neutron['provider']

  $nova = $services['nova']
  $nova_port = 8774
  $nova_proxy = 'compute'
  $nova_port_meta = 8775
  $nova_proxy_meta = 'compute-metadata'
  $hypervisor = $nova['hypervisor']
  $cpu_mode = $nova['cpu_mode']
  $console = $nova['console']

  $placement = $services['placement']
  $placement_port = 8778
  $placement_proxy = 'placement'

  # Optional services
  if $services['murano'] {
    $murano = $services['murano']
    $murano_images = $murano['images']
    $murano_image_build_dir = "${root}/murano/images"
    $murano_port = 8082
    $murano_proxy = 'application-catalog'
  }
  
  if $services['heat'] {
    $heat = $services['heat']
    $heat_port = 8004
    $heat_proxy = 'orchestration'
    $heat_port_cfn = 8000
    $heat_proxy_cfn = 'cloudformation'
    $domain_admin = $heat['domain_admin']
    $domain_admin_pass = $heat['domain_admin_pass']
  }

  if $services['horizon'] {
    $horizon = $services['horizon']
    $horizon_port = 80
    $horizon_proxy = 'dashboard'
    $plugins = $horizon['plugins']
  }

  if $services['gnocchi'] {
    $gnocchi = $services['gnocchi']
    $gnocchi_port = 8041
    $gnocchi_proxy = 'metric'
  }

  if $services['ceilometer'] {
    $ceilometer = $services['ceilometer']
    $ceilometer_polling_interval = $ceilometer['polling_interval']
  }

  if $services['aodh'] {
    $aodh = $services['aodh']
    $aodh_port = 8042
    $aodh_proxy = 'alarming'
  }

}





