# == Class: crypt::server
#
# Installs and configures a Crypt server on Ubuntu 12.04 to /usr/local/crypt, running using mod_wsgi on Apache.
# Sets the initial administrative password to 'password'
#
# === Parameters
#
# [*hostname*]
#   The hostname of the Crypt Server - defaults to $::hostname
#
# [*admin_name*]
#   The initial administrative username
#
# [*admin_email*]
#   The initial administrative email address
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
        ensure  => present,
        require => Package['build-essential'],
    }
    
    package {'python-dev':
        ensure  => present,
        require => Package['python-setuptools'],
    }
    
    package {'build-essential':
        ensure  => present,
        require => Package['git'],
    }
    
    package {'python-pip':
        ensure  => present,
        require => Package['python-dev'],
    }
    
    package {'python-virtualenv':
        ensure  => present,
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
        ensure  => present,
        owner   => www-data,
        group   => www-data,
        content => template('crypt/settings.py.erb'),
        require => Vcsrepo['/usr/local/crypt'],
    }
    
    file {'/usr/local/crypt/initial_data.json':
        ensure  => present,
        owner   => www-data,
        group   => www-data,
        source  => 'puppet:///modules/crypt/initial_data.json',
        require => Vcsrepo['/usr/local/crypt'],
    }
    
    file {'/usr/local/crypt/crypt.wsgi':
        ensure  => present,
        owner   => www-data,
        group   => www-data,
        source  => 'puppet:///modules/crypt/crypt.wsgi',
        require => Vcsrepo['/usr/local/crypt'],
    }
    
    file {'/usr/local/crypt/set_password.py':
        ensure  => present,
        owner   => www-data,
        group   => www-data,
        content => template('crypt/set_password.py.erb'),
        require => Vcsrepo['/usr/local/crypt'],
        before  => Exec['/usr/local/crypt_env/bin/python /usr/local/crypt/set_password.py'],
    }
    
    exec {'/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py syncdb --noinput':
        require => [Python::Virtualenv['/usr/local/crypt_env'],File['/usr/local/crypt/initial_data.json']],
        creates => '/usr/local/crypt/crypt.db',
        path    => '/usr/local/crypt_env/bin',
        notify  => Exec['/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py migrate'],
    }
    
    exec {'/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py migrate':
        path        => '/usr/local/crypt_env/bin',
        notify      => Exec['/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py collectstatic --noinput'],
        refreshonly => true,
    }
    
    exec {'/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py collectstatic --noinput':
        require     => Python::Virtualenv['/usr/local/crypt_env'],
        path        => '/usr/local/crypt_env/bin',
        notify      => Exec["/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py createsuperuser --noinput --email=${admin_email} --username=${admin_name}"],
        refreshonly => true,
    }
    
    exec {"/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py createsuperuser --noinput --email=${admin_email} --username=${admin_name}":
        path        => '/usr/local/crypt_env/bin',
        notify      => Exec['/usr/local/crypt_env/bin/python /usr/local/crypt/set_password.py'],
        refreshonly => true,
    }
    
    exec {'/usr/local/crypt_env/bin/python /usr/local/crypt/set_password.py':
        require     => Exec['/usr/local/crypt_env/bin/python /usr/local/crypt/manage.py syncdb --noinput'],
        path        => '/usr/local/crypt_env/bin',
        notify      => Service['httpd'],
        refreshonly => true,
    }
    
    file {'/usr/local/crypt/crypt.db': 
        owner  => www-data,
        group  => www-data,
        require => Exec['/usr/local/crypt_env/bin/python /usr/local/crypt/set_password.py'],
    }
    
    apache::vhost { "${hostname}":
        port     => '80',
        docroot  => '/usr/local/crypt',
        template => 'crypt/vhost.erb',
     }
     
     file {'/usr/local/crypt':
         ensure  => directory,
         owner   => www-data,
         group   => www-data,
         recurse => true,
     }
}
