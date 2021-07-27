# Create apache website config file. 
# By default, from template in root module templates folder e.q. 'openstack/apache.erb'
# Optionally can be passed link to custom template, like it done in horizon service
# or content of apache site config can be passed directly due @pcontent parameter.
# After site config creation function enable it and restart apache.
#
# @site        - site name e.q. 'uwsgi-placement' or 'horizon'
# @service     - OpenStack service name
# @port        - virtual host port to listen
# @proxy       - service name alias for reverse proxy
# @listen      - optional: interface address to virtual host listen on
# @template    - optional: site apache2 configuration file template
# @pcontent    - optional: rather than template can be provided already formatted content
# @service_dir - optional: some services need to provide full path to their folder
#                          horizon for example
# @depends     - requirements to run this function
#

define openstack::utils::website (

    String $site,
    String $service,
    Integer $port,
    String $proxy,
    Optional[String] $listen = '127.0.0.1',
    Optional[String] $template = 'openstack/apache.erb',
    Optional[String] $pcontent = undef,
    Optional[String] $service_dir = undef,
    Any $depends
    
  ) {

  if $pcontent == undef {
    $text = template($template)
  } else {
    $text = $pcontent
  }


  # create apache site config
  file { "/etc/apache2/sites-available/${site}.conf":
    ensure => present,
    owner => 'root',
    group => 'root',
    content => $text,
    notify => Exec["reload_apache_${site}"],
    require => $depends,
  }

  # enable site
  exec { "enable_${site}":
    command => "/usr/sbin/a2ensite ${site}.conf",
    require => File["/etc/apache2/sites-available/${site}.conf"],
    creates => "/etc/apache2/sites-enabled/${site}.conf",
    notify => Exec["reload_apache_${site}"],
  }

  # restart apache by notification only if configuration changed 
  exec { "reload_apache_${site}":
    command => '/usr/sbin/service apache2 restart',
    user => 'root',
    group => 'root',
    refreshonly => 'true'
  }

}

