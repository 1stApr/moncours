class network::ip_forwarding {

  $option = '71-enable-ip-forwarding'
  $attribute = 'net.ipv4.ip_forward'

}

class network::ip_forwarding::enable inherits network::ip_forwarding {

  network::utils::add { 'enable_ip_forwarding':
    option  => $option,
    attribute => $attribute
  }

}


class network::ip_forwarding::disable inherits network::ip_forwarding {

  network::utils::delete { 'disable_ip_forwarding':
    option  => $option,
    attribute => $attribute
  }

}
