class apache2::install inherits apache2 {

  # check if it not already defined and install depencies
  $depencies.each|$dep| {
    if !defined(Package[$dep]) {
      package { $dep:
        ensure => installed,
      }
    }
  }

  # install 
  package { $packages:
    ensure => installed,
    require => Package[$depencies]
  }

  # replace global config
  file { '/etc/apache2/apache2.conf':
    ensure => present,
    content => template('apache2/apache2.conf.erb'),
    require => Package[$packages],
    notify => Service[$services],
  }

  # ensure apache2 service running and enabled
  service { $services:
    provider => 'systemd',
    ensure => running,
    enable => true,
    require => File['/etc/apache2/apache2.conf'],
  }

  # delete default sites
  exec { 'delete_apache_default_sites':
    command => "/bin/rm -f /etc/apache2/sites-enabled/*default*",
    user => 'root',
    group => 'root',
    require => Package[$packages],
    onlyif => '/bin/ls /etc/apache2/sites-enabled/*default*',
  }

  # enable modules
  $modules.each |$module| {
    exec { "enable_apache_module_${module}":
      command => "/usr/sbin/a2enmod ${module}",
      user => 'root',
      group => 'root',
      require => Package[$packages],
      creates => "/etc/apache2/mods-enabled/${module}.load",
    }
  }

  # generate ssl
  # openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  #             -subj "/C=UA/ST=Ukraine/L=Kiev/O=Organisation/CN=hostname" \
  #             -keyout /etc/ssl/private/hostname.key -out /etc/ssl/certs/hostname.crt
  #
  exec { 'generate_self_signed_certificate':
    command => "/usr/bin/openssl req -x509 -nodes -days ${valid_days} -newkey rsa:2048 \
                                     -subj '/C=${country_code}/ST=${country}/L=${city}/O=${organization}/CN=${hostname}' \
                                     -keyout /etc/ssl/private/${hostname}.key \
                                     -out /etc/ssl/certs/${hostname}.crt",
    user => 'root',
    group => 'root',
    require => Package[$packages],
    creates => ["/etc/ssl/private/${hostname}.key",
                "/etc/ssl/certs/${hostname}.crt"]
  }

}
