# Download/Build and then upload OS images to glance
# 
# @images        - hash with image parameters
# @store         - full path to folder to store images
# @environment   - shell environment variables
# @depends       - requirements to run this function
#
define openstack::utils::image (

    Hash $images, 
    String $store,
    Tuple $environment,
    Any $depends

  ) {


  # upload and import OS images
  $images.each |$image, $value| {

    $type = $value['type']                           # image type metadata for murano apps


    # minimum root disk size in GB
    if $value['min_disk'] == undef {
      $min_disk = 1
    } else {
      $min_disk = $value['min_disk']                 
    }


    # if there are no download url provided - build image
    if $value['link'] == undef {

      # compile image name
      $name = "${image}.qcow2"

      diskimage_builder::utils::build_image { "build_image_${image}":
        distribution => $value['distribution'],
        release => $value['release'],
        image => "${store}/${name}",
        reload => Exec["import_${image}"]
      }
  
    # we have download url - download image
    } else {

      $link = $value['link']
      # extract image full name with extension from download url
      $name = regsubst($link, '^(.*[\\\/])', '')      

      exec { "download_${image}":
        command => "/usr/bin/wget ${link}",
        provider => 'shell',
        cwd => "${store}",
        creates => "${store}/${name}",
        timeout => 1800,
        notify => Exec["import_${image}"]
      }
    }

    # import image to glance
    exec { "import_${image}":
      command => "glance image-create \
                                    --name '${image}' \
                                    --file ${store}/${name} \
                                    --disk-format qcow2 \
                                    --min-disk ${min_disk} \
                                    --container-format bare \
                                    --visibility public",
      provider => 'shell',
      environment => $environment,
      timeout => 900,
      refreshonly => true,
      unless => "glance image-list | /bin/grep ${image}"
    }

  }

}



# Build and then upload OS images with preinstalled 
# Murano agent to glance
# 
# @images        - hash with image parameters
# @store         - full path to folder to store images
# @root          - root folder for store downloaded repository
# @environment   - shell environment variables
# @service       - service which calls this function
# @depends       - requirements to run this function
#
define openstack::utils::image_murano (

    Hash $images, 
    String $store,
    String $root,
    Tuple $environment,
    String $service,
    Any $depends

  ) {


  # check if image folder exist
  file { $store: 
    ensure => 'directory',
    owner => $service,
    group => $service,
    require => $depends
  }

  # build and import OS images
  $images.each |$image, $value| {

    $type = $value['type']                           # image type metadata for murano apps
    $name = "${image}.qcow2"                         # compile image name

    # minimum root disk size in GB
    if $value['min_disk'] == undef {
      $min_disk = 1
    } else {
      $min_disk = $value['min_disk']                 
    }

    # buil image
    diskimage_builder::utils::build_image { "build_murano_image_${image}":
      distribution => $value['distribution'],
      release => $value['release'],
      image => "${store}/${name}",
      murano_agent => true,
      reload => Exec["import_murano_${image}"]
    }

    # import image to glance
    exec { "import_murano_${image}":
      command => "glance image-create \
                                    --name '${image}' \
                                    --file ${store}/${name} \
                                    --disk-format qcow2 \
                                    --min-disk ${min_disk} \
                                    --container-format bare \
                                    --visibility public \
                                    --property murano_image_info='{\"title\": \"${image}\", \"type\": \"${type}\"}'",
      provider => 'shell',
      environment => $environment,
      timeout => 900,
      refreshonly => true,
      unless => "glance image-list | /bin/grep ${image}"
    }

  }

}
