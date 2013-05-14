# == Class: crypt::server
#
# Installs and configures a Crypt server on Ubuntu 12.04
#
# === Parameters
#
# [*hostname*]
#   The hostname of the Crypt Server - defaults to $::hostname
#
# [*loginhook*]
#   Whether the a loginhook should be created to run Crypt on unencrypted Macs
#
# [*skip_usernames*]
#   If you want to skip encryption for certain usernames (your local admin user, for example), put them in here
#
# [*install_app*]
#   Whether the a loginhook should be created to run Crypt on unencrypted Macs
#
# === Example
#
#  class { 'crypt::server':
#    hostname => 'http://crypt.example.com',
#    admin_name => 'someone',
#    admin_email => 'admin@example.com,
#  }
#

class crypt::server (
    $hostname = $crypt::params::hostname,
    $admin_name,
    $admin_email
    
    ) inherits crypt::params {
    
    include apache
    include apache::mod::wsgi
    
    package {'git':
        ensure => present,
    }
    
    package {'python-setuptools':
        ensure => present,
        require => Package['build-essential'],
    }
    
    package {'python-dev':
        ensure => present,
        require => Package['python-setuptools'],
    }
    
    package {'build-essential':
        ensure => present,
        require => Package['git'],
    }
    
    package {'python-pip':
        ensure => present,
        require => Package['python-dev'],
    }
    
    package {'python-virtualenv':
        ensure => present,
        require => Package['python-pip'],
    }
    
    vcsrepo { '/usr/local/crypt':
        ensure   => present,
        require  => Package['python-pip'],
        provider => git,
        source   => 'https://github.com/grahamgilbert/Crypt-Server.git',
    }

    python::virtualenv { '/usr/local/crypt_env':
        ensure       => present,
        version      => 'system',
        requirements => '/usr/local/crypt/setup/requirements.txt',
        require      => Vcsrepo['/usr/local/crypt'],
        systempkgs   => true,
    }
    
    file {'/usr/local/crypt/fvserver/settings.py':
        ensure => present,
        owner => 0,
        group => 0,
        content => template('crypt/settings.py.erb'),
        require => Vcsrepo['/usr/local/crypt'],
    }
    
    file {'/usr/local/crypt/initial_data.json':
        ensure => present,
        owner => 0,
        group => 0,
        source => 'puppet:///modules/crypt/initial_data.json',
        require => Vcsrepo['/usr/local/crypt'],
    }
    
    file {'/usr/local/crypt/crypt.wsgi':
        ensure => present,
        owner => 0,
        group => 0,
        source => 'puppet:///modules/crypt/crypt.wsgi',
        require => Vcsrepo['/usr/local/crypt'],
    }
    
    exec {'/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py syncdb --noinput':
        require => [Python::Virtualenv['/usr/local/crypt_env'],File['/usr/local/crypt/initial_data.json']],
        creates => '/usr/local/crypt/crypt.db',
        path    => '/usr/local/crypt_env/bin',
        notify  => Exec['/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py migrate'],
    }
    
    exec {'/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py migrate':
        require => Exec['/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py syncdb --noinput'],
        path    => '/usr/local/crypt_env/bin',
        notify  => Service['httpd'],
        refreshonly => true,
    }
    
    apache::vhost { "${hostname}":
        port            => '80',
        docroot         => '/usr/local/crypt',
        template => template("crypt/vhost.erb"),
        default_vhost   => true,
     }
     
     file {'/usr/local/crypt':
         ensure => directory,
         owner  => www-data,
         group  => www-data,
         recurse => true,
     }
}
