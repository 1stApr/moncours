# create database, database user and grant priviledges
#
# @dbname         - database name
# @dbrootpassword - password for root database user
# @dbuser         - new user name
# @dbpass         - password for new user
# @depends        - requirements to run this function
#
define openstack::utils::database (

    String $dbname, 
    String $dbrootpassword, 
    String $dbuser, 
    String $dbpass,
    Any $depends = Class['mariadb::install']
  
  ) {

  exec { "create_database_${dbname}":
    command => "/usr/bin/mariadb -u root \
                               -p${dbrootpassword} \
                               -e \"CREATE DATABASE ${dbname}; \
                               GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}'; \
                               FLUSH PRIVILEGES;\" ",
    user => 'root',
    group => 'root',
    require => $depends,
    onlyif => "/bin/systemctl is-active mariadb | /bin/grep active",
    unless => "/usr/bin/mariadb -u root \
                               -p${dbrootpassword} \
                               -e \"SHOW DATABASES;\" | /bin/grep ${dbname}",
  }
}


# Populate service database
#
# @service  - OpenStack service name
# @password - database password for service user
# @command  - command to populate database
# @table    - table in database to check if it already populated
# @depends  - requirements to run this function
#
define openstack::utils::database::populate (

    String $service, 
    String $password,
    String $command,
    String $table,
    Any $depends
  
  ) {

  exec { "populate_database_${service}_${table}":
    command => $command,
    user => $service,
    group => $service,
    provider => 'shell',
    require => $depends,
    unless => "/usr/bin/mariadb -u ${service} \
                                -p${password} \
                                -e \"SHOW TABLES;\" \
                                ${service} | /bin/grep ${table}"
  }

}



