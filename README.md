puppet-crypt
============

Puppet module to manager the installation of Crypt Server on Ubuntu 12.04 and Crypt Client on Mac OS X 10.7 and 10.8.

# Usage

## Crypt Server
``` puppet
class { 'crypt::server':
    hostname => 'http://crypt.example.com',
    admin_name => 'someone',
    admin_email => 'admin@example.com,
}
```

## Crypt Client

``` puppet
class { 'crypt::client':
    server_url => 'http://crypt.example.com',
    loginhook => true,
    skip_username => 'ladmin',
    install_app => true,
}
```

# Issues
This currently won't install the Crypt Client package on a Mac - you should use an alternative method to install the package, such as Munki.
