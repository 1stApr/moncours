# All OpenStack services need similar preparations for setup
# e.q. create service user, create database, clone and build 
# sources. So why not combine it in single action?
#
# @service        - OpenStack service name
# @password       - password 
# @release        - OpenStack release name. Used for cloning sources from git
# @root           - folder where to git cloning sources
# @filters        - optional: rootwrap filters if service has any
# @sudoers        - optional: sudoers rule config template
# @dbrootpassword - password of root database user
# @creates        - file name and full path created after build and setup module
#                   usually management utility, for example: '/usr/local/bin/keystone-manage'    
# @threshold      - how often rotate logs
# @keep           - how many logs to keep
#
define openstack::utils::prerequisites (

    String $service, 
    String $password,
    String $release,
    String $root,
    Optional[Array] $filters = undef, 
    Optional[String] $sudoers = undef,
    String $dbrootpassword, 
    String $creates,
    String $threshold,
    Integer $keep

  ) {

  # clone repository
  openstack::utils::git::clone { "clone_repository_${service}":
    release => $release,
    service => $service,
    root    => $root,
  }

  # create database
  openstack::utils::database { "create_database_${service}":
    dbname          => $service,
    dbrootpassword  => $dbrootpassword,
    dbuser          => $service,
    dbpass          => $password,
    depends         => Openstack::Utils::Git::Clone["clone_repository_${service}"]
  }

  # create system user and required folders
  openstack::utils::user { "create_user_${service}":
    service => $service,
    depends => Openstack::Utils::Database["create_database_${service}"]
  }

  # configure logrotate
  openstack::utils::logrotate { "${service}_logrotate":
    service => $service,
    threshold => $threshold,
    keep => $keep,
    depends => Openstack::Utils::User["create_user_${service}"]
  }

  # upload filters in loop
  if $filters != undef {

    $filters.each |$filter| {
      openstack::utils::filter { "upload_${service}_${filter}":
        service => $service,
        filter  => $filter,
        depends => Openstack::Utils::User["create_user_${service}"]
      }
    }
  }

  # create sudoers rules
  if $sudoers != undef {

    openstack::utils::sudoers { "setup_${service}_sudoers_rules":
      service => $service,
      template => $sudoers,
      depends => Openstack::Utils::User["create_user_${service}"]
    }
  }

  # create rabbitmq user 
  rabbitmq::utils::create_user { "create_rabbitmq_user_${service}":
    user     => $service,
    password => $password,
    group    => $service,
    depends  => Openstack::Utils::User["create_user_${service}"]
  }  

  # install python requirements
  openstack::utils::python::requirements { "install_python_requirements_${service}":
    service => $service,
    release => $release,
    home    => $root,
    depends => Rabbitmq::Utils::Create_user["create_rabbitmq_user_${service}"]
  }

  # setup
  openstack::utils::python::setup { "setup_${service}":
    service => $service,
    home    => "${root}/${service}",
    creates => $creates,
    depends => Openstack::Utils::Python::Requirements["install_python_requirements_${service}"]
  }

}
