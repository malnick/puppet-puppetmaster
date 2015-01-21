class my_r10k(
  $r10k_source = $puppetmaster::params::r10k_source,
) inherits puppetmaster::params {
  class { 'r10k':
      remote   => $r10k_source,
      provider => 'pe_gem',
  }
}
