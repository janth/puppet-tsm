# == Class: tsm::service::redhat
#
# Manage tsm service on redhat
#
# === Authors
#
# Toni Schmidbauer <toni@stderr.at>
#
# === Copyright
#
# Copyright 2014-2015 Toni Schmidbauer
#
class tsm::service::redhat {

  $service_script_mode = $::operatingsystemmajrelease ? {
    '7'     => '0644',
    default => '0755'
  }

  notify { "DEBUG:: Managing tsm service $::tsm::service_name ($::tsm::service_script, from $::tsm::service_script_source), tsm::service_manage is $::tsm::service_manage": }
  file { $::tsm::service_script:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => $service_script_mode,
    source  => $::tsm::service_script_source,
    require => Package[$packages],
    #notify => Exec['tsm_systemd_daemon_reload'],
    #notify => Service[ $::tsm::service_name],
  } ->
  exec { '/bin/mv /etc/init.d/dsmcad /etc/init.d/rpm-dsmcad':
    #onlyif    => 'test -r /etc/init.d/dsmcad',
    creates   => '/etc/init.d/rpm-dsmcad',
    logoutput => true,
  } ->

  /*
  if getvar('::operatingsystemmajrelease') {
    $os_maj_release = $::operatingsystemmajrelease
  } else {
    $os_versions    = split("${::operatingsystemrelease}", '[.]') # lint:ignore:only_variable_string
    $os_maj_release = $os_versions[0]
  }
  if $os_maj_release == 7 {
    ...
  } else {
    notify { "Not rhel7 ($os_maj_release), no systemctl daemon-reload": }
  }
  */

  exec { 'tsm_systemd_daemon_reload':
    path      => '/bin:/sbin:/usr/bin:/usr/sbin',
    logoutput => true,
    command   => '/usr/bin/systemctl daemon-reload',
    onlyif    => 'test -x /usr/bin/systemctl',
    require   => File[$::tsm::service_script],
    notify    => Service[ $::tsm::service_name],
  } ->
  service { $::tsm::service_name:
    ensure     => $::tsm::service_ensure,
    enable     => $::tsm::service_enable,
    hasstatus  => true,
    hasrestart => true,
        subscribe  => [
      Concat[$::tsm::config],
    #  Exec['tsm_systemd_daemon_reload'],
    #  File[$::tsm::service_script],
    ],
  }

  #File[$::tsm::service_script] -> Exec['tsm_systemd_daemon_reload'] -> Service[$::tsm::service_name]
  #File[$::tsm::service_script] -> Service[$::tsm::service_name]
  #notify { "Now RHEL service setup": }
}
