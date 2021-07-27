class network::interfaces inherits network {


  # delete default config
  file { '/etc/netplan/01-netcfg.yaml':
    ensure => absent,
    purge => true,
    force => true,
  }


  # if we have interfaces for configure
  if $interfaces != undef {

    # Configure interfaces
    $interfaces.each |String $interface, Hash $value| {

      $ip = $value[ip]
      $gw = $value[gateway]
      $dns = $value[dns]
      $mtu = $value[mtu]
      $members = $value[members]
      $remote = $value[remote]
      $local = $value[local]


      case $interface[0,2] {
        # if first two symbols 'br' interface type is bridge
        'br': {
          $config = "10-${interface}"
          $template = template('network/bridge.erb')
        }

        # todo:    
        # vlan subinterfaces over bond interface        
        # not implemented - blank config file instead
        'vl': {
          $config = "99-dummy"
          $template = template('network/dummy.erb')
        }

        # confiring GRE tunnel interface
        'gr': {
          # generate interface configuration file name
          $device_number = regsubst($interface, '[a-zA-Z]', '', 'G')
          $config = "${device_number}-gre"
          $template = template('network/gre.erb')
        }

        # configure plain interface 
        default: {
          # generate interface configuration file name
          $device_number = regsubst($interface, '[a-zA-Z]', '', 'G')
          $config = "${device_number}-${interface}"

          # use template for DHCP ip address assignment
          if $ip == 'dhcp' {
          
            $template = template('network/dhcp.erb')
          
          # use template for static IP address
          } else {
            
            $template = template('network/static.erb')
          
          }
        }
      }

      # save config file
      file { "/etc/netplan/${config}.yaml":
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => '644',
        content => $template,
        notify => Exec['netplan'],
      }  
    }

    # Apply changes
    exec { 'netplan':
      command => "/usr/sbin/netplan apply",
      user => 'root',
      group => 'root',
      refreshonly => 'true',
      notify => Refacter['refresh_network_interface_facts']
    }

    # Update facts about network interfaces
    refacter { 'refresh_network_interface_facts': 
      patterns => ["^interfaces"] 
    }
  }
}
