# https://docs.openstack.org/neutron/latest/admin/vpnaas-scenario.html#enabling-vpnaas
#
# @depends  - requirements to run this class
#
class openstack::neutron_vpnaas::install (
    
    Any $depends

) inherits openstack::neutron::install {


  # git clone neutron-fwaas
  openstack::utils::git::clone { 'clone_repository_neutron_vpnaas':
    release => $release,
    service => 'neutron-vpnaas',
    root    => $root,
  }

  # install python requirements
  openstack::utils::python::requirements { 'install_python_requirements_neutron_vpnaas':
    service => 'neutron-vpnaas',
    release => $release,
    home    => $root,
    depends => [$depends,
                Openstack::Utils::Git::Clone['clone_repository_neutron_vpnaas']]
  }

  # setup
  openstack::utils::python::setup { 'setup_neutron_vpnaas':
    service => 'neutron-vpnaas',
    home    => "${root}/neutron-vpnaas",
    creates => '/usr/local/bin/neutron-vpn-netns-wrapper', 
    depends => Openstack::Utils::Python::Requirements['install_python_requirements_neutron_vpnaas']
  }

  # populate neutron vpnaas database
  openstack::utils::database::populate { 'populate_neutron_vpnaas_database':
    service  => $service,
    password => $password,
    command  => "/usr/local/bin/neutron-db-manage --config-file /etc/neutron/neutron.conf \
                                                  --config-file /etc/neutron/neutron_vpnaas.conf \
                                                  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini \
                                                  --subproject neutron-vpnaas \
                                                  upgrade head \
              && /usr/bin/mariadb -u ${service} -p${password} neutron -e 'create table vpnaas_installed_flag (id INT);'",
    table    => 'vpnaas_installed_flag',
    depends  =>  Openstack::Utils::Python::Setup['setup_neutron_vpnaas']
  }

}

