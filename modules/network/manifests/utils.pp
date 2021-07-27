# Create config and enable kernel attribute option
#
# @option    - config file name
# @attribute - kernel attribute name (e.q. net.ipv4.ip_forward)
# 
define network::utils::add (

  String $option,
  String $attribute,

) {

  $config = "/etc/sysctl.d/${option}.conf"

  file { $config:
    ensure => present,
    owner => root,
    group => root,
    content => "${attribute} = 1",
    notify => Exec["apply_changes_${option}"],
  }

  exec { "apply_changes_${option}":
    command => "/sbin/sysctl -p -f ${config}",
    unless => "/sbin/sysctl ${attribute} | /bin/grep 1",
    require => File[$config],
    refreshonly => true
  }

}



# Delete config and disable kernel attribute option
#
# @option    - config file name
# @attribute - kernel attribute name (e.q. net.ipv4.ip_forward)
# 
define network::utils::delete (

  String $option,
  String $attribute,

) {

  $config = "/etc/sysctl.d/${option}.conf"


  file { $config:
    ensure => absent,
    purge => true,
    force => true,
    recurse => true,
    notify => Exec["apply_changes_${option}"],
  }

  exec { "apply_changes_${option}":
     command => "/sbin/sysctl -w ${attribute}=0",
     onlyif => "/sbin/sysctl ${attribute} | /bin/grep 1",
     refreshonly => true
  }

}



# Update /etc/hosts entry
#
# @ip       - host ip address
# @hostname - hostname
# @comment  - optional: host description
# 
define network::utils::host (

  String $ip,
  String $hostname,
  Optional[String] $comment = undef,

) {

  # note: grep executed with '-w' parameter
  #       This means it search an exact string
  #       So whitespace count between host values is important in sed command and in grep check
  #       If it doesn't match module will not work
  exec { "add_host_${hostname}":
    command => "/bin/sed -i '/${hostname}/c\\${ip}    ${hostname}    # ${comment}' /etc/hosts",
    unless => "/bin/grep -w '${ip}    ${hostname}    # ${comment}' /etc/hosts"
  }
  
}
