# https://docs.openstack.org/neutron/train/admin/fwaas-v2-scenario.html
#
# @depends  - requirements to run this class
#
class openstack::neutron_fwaas::install (
    
    Any $depends

) inherits openstack::neutron::install {


  # git clone neutron-fwaas
  openstack::utils::git::clone { 'clone_repository_neutron_fwaas':
    release => $release,
    service => 'neutron-fwaas',
    root    => $root,
  }

  # install python requirements
  openstack::utils::python::requirements { 'install_python_requirements_neutron_fwaas':
    service => 'neutron-fwaas',
    release => $release,
    home    => $root,
    depends => [$depends,
                Openstack::Utils::Git::Clone['clone_repository_neutron_fwaas']]
  }

  # setup
  openstack::utils::python::setup { 'setup_neutron_fwaas':
    service => 'neutron-fwaas',
    home    => "${root}/neutron-fwaas",
    creates => '/usr/local/bin/neutron-fwaas-migrate-v1-to-v2',
    depends => Openstack::Utils::Python::Requirements['install_python_requirements_neutron_fwaas']
  }

  # populate neutron fwaas database
  openstack::utils::database::populate { 'populate_neutron_fwaas_database':
    service  => $service,
    password => $password,
    command  => "/usr/local/bin/neutron-db-manage --config-file /etc/neutron/neutron.conf \
                                                  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini \
                                                  --subproject neutron-fwaas \
                                                  upgrade head \
              && /usr/bin/mariadb -u ${service} -p${password} neutron -e 'create table fwaas_installed_flag (id INT);'",
    table    => 'fwaas_installed_flag',
    depends  =>  Openstack::Utils::Python::Setup['setup_neutron_fwaas']
  }

}

