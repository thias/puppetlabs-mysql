# Class: mysql::backup
#
# This module handles ...
#
# Parameters:
#   [*backupuser*]     - The name of the mysql backup user.
#   [*backuppassword*] - The password of the mysql backup user.
#   [*backupdir*]      - The target directory of the mysqldump.
#   [*backupcompress*] - Boolean to compress backup with bzip2.
#
# Actions:
#   GRANT SELECT, RELOAD, LOCK TABLES ON *.* TO 'user'@'localhost'
#    IDENTIFIED BY 'password';
#
# Requires:
#   Class['mysql::config']
#
# Sample Usage:
#   class { 'mysql::backup':
#     backupuser     => 'myuser',
#     backuppassword => 'mypassword',
#     backupdir      => '/tmp/backups',
#     backupcompress => true,
#   }
#
class mysql::backup (
  $backupuser,
  $backuppassword,
  $backupdir,
  $backupdays = '5',
  $backupcompress = true,
  $backupsplitdb = false,
  $backupsilent = true,
  $ensure = 'present'
) {

  database_user { "${backupuser}@localhost":
    ensure        => $ensure,
    password_hash => mysql_password($backuppassword),
    provider      => 'mysql',
    require       => Class['mysql::config'],
  }

  database_grant { "${backupuser}@localhost":
    privileges => [ 'Select_priv', 'Reload_priv', 'Lock_tables_priv', 'Show_view_priv', 'Event_priv' ],
    require    => Database_user["${backupuser}@localhost"],
  }

  if $backupsilent {
    $cron_command = '/usr/local/sbin/mysqlbackup.sh >/dev/null'
  } else {
    $cron_command = '/usr/local/sbin/mysqlbackup.sh'
  }
  cron { 'mysql-backup':
    ensure  => $ensure,
    command => $cron_command,
    user    => 'root',
    hour    => 23,
    minute  => 5,
    require => File['mysqlbackup.sh'],
  }

  $backup_template = $backupsplitdb ? {
    true  => 'mysql/mysqlbackup-splitdb.sh.erb',
    false => 'mysql/mysqlbackup.sh.erb',
  }
  file { 'mysqlbackup.sh':
    ensure  => $ensure,
    path    => '/usr/local/sbin/mysqlbackup.sh',
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
    content => template($backup_template),
  }

  file { 'mysqlbackupdir':
    ensure => 'directory',
    path   => $backupdir,
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
  }
  if $backupsplitdb {
    file { [
      "${backupdir}/day",
      "${backupdir}/month",
    ]:
      ensure => 'directory',
      mode   => '0700',
      owner  => 'root',
      group  => 'root',
    }
  }

}
