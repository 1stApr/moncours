# create rabbitmq user
#
# @user     - user name
# @password - user password
# @group    - user tag in rabbitmq terms
# @depends  - requirements to run this function
#

define rabbitmq::utils::create_user(
    
    String $user, 
    String $password, 
    String $group,
    Any $depends
  
  ) {

  exec { "create_rabbitmq_user_${user}":
    command => "/usr/sbin/rabbitmqctl add_user ${user} ${password} \
             && /usr/sbin/rabbitmqctl set_user_tags ${user} ${group} \
             && /usr/sbin/rabbitmqctl set_permissions -p / ${user} \".*\" \".*\" \".*\"",
    user => 'root',
    group => 'root',
    unless => "/usr/sbin/rabbitmqctl list_users | /bin/grep ${user}",
    require => $depends
  }

}

# create channel and grant permissions to user
#
# @user     - user name
# @channel  - channel name
# @depends  - requirements to run this function
#
define rabbitmq::utils::create_channel(
  
    String $user, 
    String $channel,
    Any $depends
  
  ) {

  exec { "create_channel_${channel}":
    command => "/usr/sbin/rabbitmqctl add_vhost ${channel} \
             && /usr/sbin/rabbitmqctl set_permissions -p ${channel} ${user} \".*\" \".*\" \".*\"",
    user => 'root',
    group => 'root',
    unless => "/usr/sbin/rabbitmqctl list_vhosts | /bin/grep ${channel}",
    require => $depends
  }
}


