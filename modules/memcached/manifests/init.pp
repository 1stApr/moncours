class memcached {

  $packages = ['memcached']
  $services = ['memcached']

  # parameters from Hiera
  $memcached = lookup('memcached', Hash)

  $bind_address = $memcached['bind_address']

}

