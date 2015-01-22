class puppetmaster::webhook {

  file {'/etc/puppetlabs/puppet/webhook':
    ensure    => directory,
    recurse   => true,
    source    => 'puppet:///modules/puppetmaster/webhook',
    notify    => Service['r10k_webhook'],
  }

  service {'r10k_webhook':
    ensure => running,
    hasstatus => false,
    start     => '/etc/puppetlabs/puppet/webhook/bin/server start',
    stop      => '/etc/puppetlabs/puppet/webhook/bin/server stop', 
    restart   => '/etc/puppetlabs/puppet/webhook/bin/server restart',
    require   => File['/etc/puppetlabs/puppet/webhook'],
  }


}
