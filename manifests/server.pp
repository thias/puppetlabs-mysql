# Class: mysql0::server
#
# manages the installation of the mysql server.  manages the package, service,
# my.cnf
#
# Parameters:
#   [*package_name*] - name of package
#   [*service_name*] - name of service
#   [*config_hash*]  - hash of config parameters that need to be set.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql0::server (
  $package_name     = $mysql0::params::server_package_name,
  $package_ensure   = 'present',
  $service_name     = $mysql0::params::service_name,
  $service_provider = $mysql0::params::service_provider,
  $config_hash      = {},
  $enabled          = true,
  $manage_service   = true,
  $backup           = false
) inherits mysql0::params {

  Class['mysql0::server'] -> Class['mysql0::config']

  $config_class = { 'mysql0::config' => $config_hash }

  #create_resources( 'class', $config_class )
  class { '::mysql0::config':
    root_password => $config_hash['root_password'],
  }

  package { 'mysql-server':
    ensure => $package_ensure,
    name   => $package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if $manage_service {
    service { 'mysqld':
      ensure   => $service_ensure,
      name     => $service_name,
      enable   => $enabled,
      require  => Package['mysql-server'],
      provider => $service_provider,
    }
  }

  if $backup {
    # Rely on hiera to look parameters up when using this
    include '::mysql0::backup'
  }

}
