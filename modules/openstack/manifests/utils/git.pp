# Clone git repository
#
# @release  - product release name
# @service  - OpenStack service name
# @root     - root folder for store downloaded repository
#
define openstack::utils::git::clone(
  
    String $release, 
    String $service, 
    String $root

  ) {


  exec { "git_clone_${service}":
    command => "/usr/bin/git clone https://git.openstack.org/openstack/${service} -b ${release} --depth 1",
    user => 'root',
    group => 'root',
    cwd => $root,
    timeout => '1200',
    unless => "/usr/bin/test -f ${root}/${service}/setup.py",
  }

}
