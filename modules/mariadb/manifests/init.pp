class mariadb {

  # hiera values
  $mariadb = lookup('mariadb', Hash)
  $version = $mariadb['version']
  $bind_address = $mariadb['bind_address']
  $password = $mariadb['password']

  $depencies = ['software-properties-common', 'lsof']
  $packages = ["mariadb-server-${version}", "mariadb-client-${version}", "mariadb-common"]
  $services = ['mariadb']
  $repository = '/etc/apt/sources.list.d/mariadb.list'
  $home = '/var/lib/mysql'
  $config = '/etc/mysql/mariadb.conf.d/99-openstack.cnf'

  # files created during maridb initialization 
  # scenario check it presense to ensure that this operations are already done
  # this quite faster than make query to mariadb
  $lock_hardening = '/var/lib/mysql/cluster_initialized.lock'
  $lock_password = '/var/lib/mysql/root_password_set.lock'

}
