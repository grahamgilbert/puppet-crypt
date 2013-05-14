# == Class: crypt::client
#
# Installs and configures a Crypt client
#
# === Parameters
#
# [*server_url*]
#   The url of the Crypt Server - defaults to http://crypt
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
#  class { 'crypt::client':
#    server_url => 'http://crypt.example.com',
#    loginhook => true,
#    skip_usernames => ['ladmin','root'],
#    install_app => true,
#  }
#

class crypt::client (
    $server_url     = $crypt::params::server_url,
    $loginhook      = $crypt::params::loginhook,
    $skip_usernames = ['root','ladmin'],
    $install_app    = undef,
    
    ) inherits crypt::params {
    
    if ! defined(File['/var/lib/puppet/crypt']) {
      file { '/var/lib/puppet/crypt':
        ensure => directory,
      }
    }

    ##Write out the contents of the template to a mobileconfig file (this needs to be cleaned up)
    file {'/var/lib/puppet/crypt/com.grahamgilbert.crypt.mobileconfig':
        content => template('crypt/com.grahamgilbert.crypt.erb'),
        owner   => 0,
        group   => 0,
        mode    => '0755',
    }

    ##Install the profile
    mac_profiles_handler::manage { 'com.grahamgilbert.crypt':
        ensure      => present,
        file_source => '/var/lib/puppet/crypt/com.grahamgilbert.crypt.mobileconfig',
        require     => File['/var/lib/puppet/crypt/com.grahamgilbert.crypt.mobileconfig']
    }
    
    if $loginhook {
        file {'/var/lib/puppet/crypt/filevault.sh':
            content => template('crypt/filevault.sh.erb'),
            owner   => 0,
            group   => 0,
            mode    => '0755',
        }
        
        mac_admin::loginhook {'crypt-hook':
            script => '/var/lib/puppet/crypt/filevault.sh'
        }
    }
    
    # Todo: Install the app.
}