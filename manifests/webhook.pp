class puppetmaster::webhook {

  package {'ruby1.9.3':
    ensure => present,
  }

  package {'sinatra_gem':
    ensure    => present,
    name      => 'sinatra',
    provider  => 'gem',
    require   => Package['ruby1.9.3'],
  }
  
  exec {'git_gem':
    command => '/usr/bin/gem install git',
    require => Package['ruby1.9.3'],
  }
  #  package {'git_gem':
  # ensure    => '1.2.9',
  # name      => 'git',
  # provider  => 'gem',
  # require   => Package['ruby1.9.3'],
  #}

  package {'webrick_gem':
    ensure    => present,
    name      => 'webrick',
    provider  => 'gem',
    require   => Package['ruby1.9.3'],
  }

  file {'/etc/puppetlabs/puppet/webhook':
    ensure    => directory,
    recurse   => true,
    source    => 'puppet:///modules/puppetmaster/webhook',
    notify    => Service['r10k_webhook'],
  }

  file {'/etc/puppetlabs/puppet/webhook/logs':
    ensure  => directory,
  }

  service {'r10k_webhook':
    ensure    => running,
    path      => '/etc/puppetlabs/puppet/webhook/bin/server',
    status    => '/etc/puppetlabs/puppet/webhook/bin/server status',
    start     => '/etc/puppetlabs/puppet/webhook/bin/server start',
    stop      => '/etc/puppetlabs/puppet/webhook/bin/server stop', 
    restart   => '/etc/puppetlabs/puppet/webhook/bin/server restart',
    require   => [Package['webrick_gem','sinatra_gem','ruby1.9.3'], Exec['git_gem'], File['/etc/puppetlabs/puppet/webhook']],
  }


}
