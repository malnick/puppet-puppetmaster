class puppetmaster (
  $autosign_bool  = $puppetmaster::params::autosign_bool,
  $r10k_source    = $puppetmaster::params::r10k_source,
  
)inherits puppetmaster::params{

  include puppetmaster::service

  class {puppetmaster::configfiles:
    autosign_bool => $autosign_bool,
  }

  class {puppetmaster::r10k:
    r10k_source => $r10k_source,
    require     => Class[puppetmaster::configfiles],
  }
}
