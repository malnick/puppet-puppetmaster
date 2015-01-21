class my_r10k {
  class { 'r10k':
      remote   => 'git@github.com:malnick/puppet-control.git',
      provider => 'pe_gem',
  }
}
