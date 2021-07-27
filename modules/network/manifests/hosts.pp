class network::hosts inherits network {


  # delete 127.0.1.1 record if exists
  exec { 'del_127.0.1.1':
    command => "/bin/sed -i '/127.0.1.1/d' /etc/hosts",
    onlyif => '/bin/grep 127.0.1.1 /etc/hosts',
  }

  # Update localhost entry for IPv4 
  network::utils::host { 'update_localhost':
    ip    => '127.0.0.1',
    hostname => 'localhost'
  }

  # if we have hosts to configure
  if $interfaces != undef {

    # Write hosts data
    $interfaces.each |String $interface, Hash $value| {

      if $value[hostname] != undef {
        network::utils::host { "add_hostname_${interface}":
          ip   => regsubst($value[ip], '\/[0-9]{1,2}', ''),     # cut off network mask
          hostname  => $value[hostname],
          comment   => $value[comment]
        }
      }
    }
  }
}
