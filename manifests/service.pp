class puppetmaster::service {

  service {'pe-httpd':
    ensure  => running,
    enable  => true,
  }

  service {'pe-puppetserver':
    ensure  => running,
    enable  => true,
  }

}
