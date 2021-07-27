class rabbitmq {

  $config = '/etc/rabbitmq/rabbitmq-env.conf'
  $limits = '/etc/systemd/system/rabbitmq-server.service.d'
  $depencies = ['erlang-nox']
  $packages = ['rabbitmq-server']
  $services = ['rabbitmq-server']

  # Hiera values
  $rabbitmq = lookup('rabbitmq', Hash)
  $bind_address = $rabbitmq['bind_address']
  $user = $rabbitmq['user']
  $password = $rabbitmq['password']

}
