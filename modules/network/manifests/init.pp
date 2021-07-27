class network {

  $network = lookup('network', Hash)
  $interfaces = $network['interfaces']    

  
  include network::interfaces
  include network::hosts   


  if $network['ip_forwarding'] == true {
    include network::ip_forwarding::enable
  } else {
    include network::ip_forwarding::disable
  }


  if $network['ip_v6'] == true {
    include network::ip_v6::enable
  } else {
    include network::ip_v6::disable
  }
  
}
