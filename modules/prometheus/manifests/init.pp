class prometheus {


  $depencies = ['wget', 'tar', 'curl']

  $service_dir = '/opt/prometheus'
  $config_dir = '/etc/prometheus'
  $data_dir = '/var/lib/prometheus'


  # Prometheus parameters from Hiera
  $prometheus = lookup('prometheus', Hash)

  $version = $prometheus['version']
  $retention = $prometheus['retention']
  $listen = $prometheus['listen']


  # if alertmanager defined in yaml config
  if $prometheus['alertmanager'] {
    $alertmanager = $prometheus['alertmanager']
    $alert_version = $alertmanager['version']
    $openstack_credentials = $alertmanager['openstack_credentials']

    $executor_listen = '127.0.0.1'
    $executor_port = 39091
  }


}

