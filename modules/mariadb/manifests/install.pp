class mariadb::install inherits mariadb {

  # check if it not already defined and install depencies
  $depencies.each|$dep| {
    if !defined(Package[$dep]) {
      package { $dep:
        ensure => installed,
      }
    }
  }

  # install mariadb apt repository
  apt::utils::apt_repository { 'mariadb':
    key => '0xF1656F24C74CD1D8',
    file => $repository,
    repository => "deb [arch=amd64] http://ftp.eenet.ee/pub/mariadb/repo/${version}/ubuntu ${::lsbdistcodename} main",
  }

  # install packages common for all roles
  package { $packages:
    ensure => installed,
    require => [Apt::Utils::Apt_repository['mariadb'],
                Package[$depencies]]
  }

  # create config
  file { $config:
    ensure => present,
    content => template('mariadb/openstack.cnf.erb'),
    require => Package[$packages],
    notify => Service[$services]
  }

  # ensure service is running and enabled
	service { $services:
		ensure => running,
		enable => true,
		require => File[$config]
	}
  
  # hardening mariadb: 
  #   remove_anonymous_users
  #   remove remote root
  #   remove test database
  #   remove privileges on test database
  #   reload privilege tables  
  exec { 'hardening_mariadb':
    command => "/usr/bin/mariadb -u root -e \"DELETE FROM mysql.global_priv WHERE User=''\" \
             && /usr/bin/mariadb -u root -e \"DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')\" \
             && /usr/bin/mariadb -u root -e \"DROP DATABASE IF EXISTS test\" \
             && /usr/bin/mariadb -u root -e \"DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'\" \
             && /usr/bin/mariadb -u root -e \"FLUSH PRIVILEGES\" \
             && /usr/bin/touch ${lock_hardening}",
    user => 'root',
    group => 'root',
    provider => 'shell',
    require => Service[$services],
    onlyif => [ "/bin/systemctl is-active mariadb | /bin/grep active"],
    unless => "/usr/bin/test -f ${lock_hardening}",
  }

  # setup root password
  exec { 'set_mariadb_root_password':
    command => "/usr/bin/mysqladmin --user root password \"${password}\" \
             && /usr/bin/touch ${lock_password}",
    user => 'root',
    group => 'root',
    require => Exec["hardening_mariadb"],
    onlyif => [ "/bin/systemctl is-active mariadb | /bin/grep active"],
    unless => "/usr/bin/test -f ${lock_password}",
  }

}
