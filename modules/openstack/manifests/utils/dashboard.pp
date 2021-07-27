# Installs Horizon Dashboard plugin
#
# @plugin            - horizon plugin name, must be equal to plugin name in git repository
# @release           - OpenStack release name
# @root              - root folder for store downloaded repository
# @dashboard         - horizon enabled plugins folder 
# @check             - file name used to check if plugin files already copied to dashboard
# @settings          - plugin settings file name
# @settings_template - plugin settings file template
# @policy_template   - plugin policy file template
#
define openstack::utils::dashboard::plugin(
  
    String $plugin, 
    String $release, 
    String $root,
    String $dashboard,
    String $check,
    String $settings,
    String $settings_template,
    String $policy_template

  ) {

  # some constants can be evaluated
  $plugin_underline = regsubst($plugin, '-', '_', 'G')
  $policy = regsubst($plugin_underline, 'dashboard', 'policy.json', 'G')

  # murano-dashboard plugin developers doesn't obey plugin structure convention
  # and place UI files in different folder than expected
  # so we need this dirty hack to point murano-dashboard UI files location
  if $plugin == 'murano-dashboard' {
    $plugin_ui = "${root}/${plugin}/muranodashboard/local/enabled/_[1-9]*.py"
  } else {
    $plugin_ui = "${root}/${plugin}/${plugin_underline}/enabled/_[1-9]*.py"
  }


  # clone repository
  openstack::utils::git::clone { "clone_repository_${plugin}":
    release => $release,
    service => $plugin,
    root    => $root,
  }

  # install python requirements
  openstack::utils::python::requirements { "install_python_requirements_${plugin}":
    service     => $plugin,
    release     => $release,
    home        => $root,
    depends     => Openstack::Utils::Git::Clone["clone_repository_${plugin}"]
  }

  # setup
  openstack::utils::python::setup { "setup_${plugin}":
    service => $plugin,
    home    => "${root}/${plugin}",
    creates => "${root}/${plugin}/build",
    depends => Openstack::Utils::Python::Requirements["install_python_requirements_${plugin}"]
  }

  # copy plugin UI to dashboard
  exec { "enable_plugin_${plugin}":
    command => "/bin/cp ${plugin_ui} ${dashboard}/local/enabled",
    provider => 'shell',
    user => 'horizon',
    group => 'horizon',
    unless => "/bin/ls ${dashboard}/local/enabled | grep ${check}",
    require => Openstack::Utils::Python::Setup["setup_${plugin}"]
  }

  # create policy file
  file { "${dashboard}/conf/${policy}":
    ensure => present,
    owner => 'horizon',
    group => 'horizon',
    content => $policy_template,
    require => Exec["enable_plugin_${plugin}"]
  }

  # create settings file 
  file { "${dashboard}/local/local_settings.d/${settings}":
    ensure => present,
    owner => 'horizon',
    group => 'horizon',
    content => $settings_template,
    require => Exec["enable_plugin_${plugin}"]
  }
  
  # copy static resources
  exec { "django_collectstatic_${plugin}":
    command => "/usr/bin/python3.6 manage.py collectstatic --noinput \
             && /usr/bin/touch ${root}/${plugin}/collectstatic.done",
    provider => 'shell',
    cwd => "${root}/${plugin}",
    environment => "DJANGO_SETTINGS_MODULE=openstack_dashboard.settings",
    creates => "${root}/${plugin}/collectstatic.done",
    notify => Exec["reload_apache_${plugin}"],
    require => File["${dashboard}/local/local_settings.d/${settings}"]
  }

  # copy Heat template generator icons
  if $plugin == 'heat-dashboard' {
    exec { "copy_${plugin}_template_generator_icons":
      command => "/bin/cp -R ${root}/${plugin}/heat_dashboard/static/dashboard/project/heat_dashboard  ${dashboard}/../static/dashboard/project/",
      provider => 'shell',
      user => 'horizon',
      group => 'horizon',
      unless => "/usr/bin/test -d ${dashboard}/../static/dashboard/project/heat_dashboard",
      notify => Exec["reload_apache_${plugin}"],
      require => Exec["django_collectstatic_${plugin}"]
    }
  }

  # restart apache by notification only if configuration changed 
  exec { "reload_apache_${plugin}":
    command => '/usr/sbin/service apache2 restart',
    user => 'root',
    group => 'root',
    refreshonly => 'true'
  }

}

