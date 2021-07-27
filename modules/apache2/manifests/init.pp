class apache2 {


  $depencies = ['openssl']
  $packages = ['apache2', 'libapache2-mod-proxy-uwsgi', 'libapache2-mod-wsgi-py3']
  $services = ['apache2']

  # apache parameters from Hiera
  $apache = lookup('apache', Hash)

  $modules = $apache['modules']

  $certificate = $apache['certificate']
  $valid_days = $certificate['valid_days']
  $country_code = $certificate['country_code']
  $country = $certificate['country']
  $city = $certificate['city']
  $organization = $certificate['organization']

}
