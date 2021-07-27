class nfs {

  # hiera values
  $nfs = lookup('nfs-server', Hash)
  $root = $nfs['root']

  $packages = ['nfs-kernel-server']
  $services = ['nfs-kernel-server']

  $config = '/etc/exports'
  
}
