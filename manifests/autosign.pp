class autosign {
  file {'/etc/puppetlabs/puppet/autosign.conf':
    ensure => present,
    content => '*',
  }
}
