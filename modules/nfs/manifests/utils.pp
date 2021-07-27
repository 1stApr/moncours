# Add folder to NFS export and set given owner credentials
#
# @host    - allow connections from this host
# @folder  - folder to export
# @owner   - set folder owner to match UID-GUID of folder on server to client UID-GUID
#

define nfs::utils::add_export(String $host, String $folder, String $owner) {

  # compile export configuration parameter string
  $share = "${folder} ${host}(rw,sync,no_subtree_check,no_root_squash)"

  # ensure export folders exists
  file { $folder:
    ensure => 'directory',
    owner => $owner,
    group => $owner,
    mode => '777',
  }

  # add export
  exec { "add_export_${host}_${folder}_${owner}":
      command => "/bin/echo '${share}' >> /etc/exports",
      user => 'root',
      group => 'root',
      require => File[$folder],
      notify => Exec["apply_export_${host}_${folder}_${owner}"],
      unless => "/bin/grep '${share}' /etc/exports"
  }

  # apply changes
  exec { "apply_export_${host}_${folder}_${owner}":
      command => "/usr/sbin/exportfs -ra",
      user => 'root',
      group => 'root',
      refreshonly => 'true',
  }

}
