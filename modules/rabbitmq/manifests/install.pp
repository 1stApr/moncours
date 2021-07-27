class rabbitmq::install inherits rabbitmq {


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

  # create rabbitmq limits configuration directory
  # with systemd it configures througth files in /etc/systemd/system directory
	file { $limits:
		ensure => 'directory',
		recurse => true,
    require => Package[$packages],
	}

  # update limits file
  file { "${limits}/limits.conf":
    ensure => present,
    content => template('rabbitmq/rabbitmq.limits.erb'),
    require => File[$limits],
    notify => Exec['reload_systemd'],
  }

  # reload systemd to reload units
  exec { 'reload_systemd':
    command => "/bin/systemctl daemon-reload ",
    user => 'root',
    group => 'root',
    refreshonly => 'true',
    require => File["${limits}/limits.conf"],
    notify => Service[$services],
  }

  # create config
  file { $config:
    ensure => present,
    content => template('rabbitmq/rabbitmq-env.conf.erb'),
    mode => '0644',
    notify => Service[$services],
    require => Package[$packages],
  }

  # ensure rabbitmq service running and enabled
  service { $services:
    provider => 'systemd',
    ensure => running,
    enable => true,
    require => File["${limits}/limits.conf",
                    $config],               
  }

  #
  # Configuration tasks
  #

  # add 'admin' user
  exec { "configure_user_accounts_${hostname}":
    command => "/usr/sbin/rabbitmqctl add_user ${user} ${password} \
             && /usr/sbin/rabbitmqctl set_user_tags ${user} administrator \
             && /usr/sbin/rabbitmqctl set_permissions -p / ${user} \".*\" \".*\" \".*\"",
    user => 'root',
    group => 'root',
    require => Service[$services],
    unless => "/usr/sbin/rabbitmqctl list_users | /bin/grep ${user}",
  }

  # delete default user 'guest'
  exec { "delete_guest_user_${hostname}":
    command => "/usr/sbin/rabbitmqctl delete_user guest",
    user => 'root',
    group => 'root',
    require => Service[$services],
    onlyif => "/usr/sbin/rabbitmqctl list_users | /bin/grep guest",
  }

}
