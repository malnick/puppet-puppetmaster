class configfiles (

  $autosign_bool  = true,
  $auth_conf      = $puppetmaster::params::auth_conf, #'puppet:///modules/puppetmaster/auth.conf',
  $puppet_conf    = $puppetmaster::params::puppet_conf, #'puppet:///modules/puppetmaster/puppet.conf',

)inherits puppetmaster::params {

  # INI File Line for puppet.conf

}
