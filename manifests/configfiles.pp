class configfiles (

  $autosign_bool  = true,
  $auth_conf      = $puppetmaster::params::auth_conf, #'puppet:///modules/puppetmaster/auth.conf',
  $puppet_conf    = $puppetmaster::params::puppet_conf, #'puppet:///modules/puppetmaster/puppet.conf',

)inherits puppetmaster::params {

  Ini_setting{
    notify => Service['pe-httpd','pe-puppetserver'],
  }

  # INI File Line for puppet.conf
  ini_setting { "autosign":
      ensure  => present,
      path    => '/etc/puppetlabs/puppet/puppet.conf',
      section => 'master',
      setting => 'autosign',
      value   => 'true',
  }

}
