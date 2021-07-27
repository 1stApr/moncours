# Install python openstack requirements from requirements.txt file
# Optionally can be provided constraints file, full path to file or
# http link for limiting max or min version of installed packages
#
# @service      - OpenStack service name
# @release      - OpenStack release name
# @home         - folder where service source files are located
# @depends      - requirements to run this function
#
define openstack::utils::python::requirements (

    String $service,
    String $release,
    String $home,
    Any $depends

  ) {

  
  # install python requirements
  exec { "install_python_requirements_${service}":
      command => "/usr/bin/pip3 install \
                                -r ${home}/${service}/requirements.txt \
                                -c https://opendev.org/openstack/requirements/raw/branch/${release}/upper-constraints.txt", 
      user => 'root',
      group => 'root',
      cwd => "${home}/${service}",
      creates => "${home}/${service}/requirements.installed",
      require => $depends
  }

  # rename reqirements file to prevent execution on each puppet run
  exec { "rename_python_requirements_${service}":
      command => "/bin/mv ${home}/${service}/requirements.txt ${home}/${service}/requirements.installed", 
      user => 'root',
      group => 'root',
      cwd => "${home}/${service}",
      creates => "${home}/${service}/requirements.installed",
      require => Exec["install_python_requirements_${service}"],
  }

}



# Setup OpenStack component
#
# @service   - OpenStack service name
# @home      - folder where service source files are located
# @creates   - optional: file to check if this function was executed before
# @depends   - requirements to run this function
#
define openstack::utils::python::setup (

    String $service,
    String $home,
    Optional[String] $creates = undef, 
    Any $depends

  ) {

  exec { "setup_${service}":
    command => "/usr/bin/python3 setup.py install",
    user => 'root',
    group => 'root',
    cwd => "${home}",
    require => $depends,
    creates => $creates
  }
  
}
