# Build Cloud image 
# Builds 'minimal' version of image with less packages as possible
# Includes openssh-server package by default
# Enables cloud-init script datasources and sets it to 'ConfigDrive' 
# and 'OpenStack' by default
# Builds only Debian based linux distribution images
#
# @distribution - linux distribution (debian or ubuntu)
# @release      - OS release to build
# @image        - full path with image name and extension for created image
#                 for example: /opt/stack/images/ubuntu-minimal-bionic-ssh-x64.qcow2
# @murano-agent - optional: do enable murano-agent
# @reload       - service or event altered to reload on function completion
#
define diskimage_builder::utils::build_image (
  
  String $distribution,
  String $release,
  String $image,
  Optional[Boolean] $murano_agent = false,
  Any $reload,

  ) {

  
  # enable murano-agent depending on image purpose
  if $murano_agent == false {
    $packages = '-p openssh-server -p cloud-init'
  } else {
    $packages = '-p openssh-server -p murano-agent -p cloud-init'
  }

  
  # build image
  # note: 'no-tmpfs' options used because in systems with low RAM amount
  #       couple launches of imagebuilder can consume all available RAM
  #       in systems with high RAM amount or on systems without some
  #       important production services - remove this parameter
  #       since it slowdown building process 
  #
  exec { "build_image_${image}":
      command => "DIB_RELEASE=${release} \
                  DIB_CLOUD_INIT_DATASOURCE=\"ConfigDrive, OpenStack\" \
                  DIB_DHCP_TIMEOUT=60 \
                  /usr/local/bin/disk-image-create vm ${distribution}-minimal \
                                                      dhcp-all-interfaces \
                                                      -c \
                                                      -a amd64 \
                                                      --no-tmpfs \
                                                      ${packages} \
                                                      -o ${image}",
      user => 'root',
      group => 'root',
      provider => 'shell',
      timeout => 1800,
      creates => $image,
      notify => $reload
  }

}

