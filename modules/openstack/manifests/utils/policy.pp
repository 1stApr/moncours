# Generate oslo policy file
#
# @service      - OpenStack service name
# @config       - optional: OpenStack service main configuration file
# @output       - optional: file to save policy
# @depends      - requirements to run this function
#
define openstack::utils::policy (

    String $service,
    Optional[String] $config = "/etc/${service}/${service}.conf", 
    Optional[String] $output = "/etc/${service}/policy.yaml", 
    Optional[String] $sample = undef,
    Any $depends

  ) {

  
  # there are entry point in policy enforcer for service
  #
  # sudo pip3 install entry-point-inspector
  # epi group show oslo.policy.enforcer
  #
  if $sample == undef {

    exec { "generate_oslo_policy_${service}":
      command => "/usr/local/bin/oslopolicy-policy-generator \
                                          --config-file ${config} --namespace ${service} --output-file ${output}",
      user => $service,
      group => $service,
      provider => 'shell',
      require => $depends,
      creates => $output
    }

  # no entry point
  } else {

    exec { "generate_oslo_sample_policy_${service}":
      command => "/usr/local/bin/oslopolicy-sample-generator \
                                          --config-file ${sample} --output-file ${output}",
      user => $service,
      group => $service,
      provider => 'shell',
      notify => Exec["enable_sample_policy_${service}"],
      require => $depends,
      creates => $output
    }

    # uncomment policy rules
    exec { "enable_sample_policy_${service}":
      command => "/bin/sed -i 's/#\"/\"/g' ${output}",
      user => $service,
      group => $service,
      provider => 'shell',
      refreshonly => true
    }
  }


}
