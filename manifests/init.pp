class puppetmaster (
  $autosign_bool  = $puppetmaster::params::autosign_bool,
  $r10k_source    = $puppetmaster::params::r10k_source,
  
)inherits puppetmaster::params{

  stage {'webhook':
    require => Stage['main'],
  }
  
  class { puppetmaster::webhook:
    stage => 'webhook',
  }

  # Main Stage
  include puppetmaster::service

  class {puppetmaster::configfiles:
    autosign_bool => $autosign_bool,
  }

  class {puppetmaster::r10k:
    r10k_source => $r10k_source,
    require     => Class[puppetmaster::configfiles],
  }
}
