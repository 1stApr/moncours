# Commands bulk run
# Commands and corresponding checks passed in Puppet Hash
# 
# @commands     - hash with commands and its checks
# @environment  - optional: shell environment variables
# @depends      - requirements to run this function
#
define openstack::utils::bulkrun (

    Hash $commands, 
    Optional[Tuple] $environment = undef,
    Any $depends

  ) {

  $commands.each |$command, $code| {

    exec { "bulk_run_${command}":
      command => $code[0],
      provider => 'shell',
      environment => $environment,
      unless => $code[1],
      require => $depends
    }
  }

}

