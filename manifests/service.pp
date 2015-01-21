class puppetmaster::service {

  service {'pe-httpd':
    ensure => running,
  }

  service {'pe-puppetserver':
    ensure => running,
  }

}
