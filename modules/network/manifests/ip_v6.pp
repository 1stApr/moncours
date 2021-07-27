class network::ip_v6 {

  $option = '70-disable-ipv6'
  $attribute = 'net.ipv6.conf.all.disable_ipv6'

}

class network::ip_v6::disable inherits network::ip_v6 {

  network::utils::add { 'disable_ip_v6':
    option  => $option,
    attribute => $attribute
  }

}


class network::ip_v6::enable inherits network::ip_v6 {

  network::utils::delete { 'enable_ip_v6':
    option  => $option,
    attribute => $attribute
  }

}
