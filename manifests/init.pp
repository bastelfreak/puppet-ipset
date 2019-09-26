# @summary module to install the ipset tooling and to manage individual ipsets
#
# @param packages
#   The name of the package we want to install
#
# @param service
#   The name of the service that we're going to manage
#
# @param service_ensure
#   Desired state of the service
#
# @param enable
#   Boolean to decide if we want to have the service in autostart or not
#
class ipset (
  Array[String[1]] $packages,
  String[1] $service,
  Stdlib::Ensure::Service $service_ensure,
  Boolean $enable,
  Enum['present', 'absent', 'latest'] $package_ensure,
  Stdlib::Absolutepath $config_path,
){
  package{$ipset::packages:
    ensure => $package_ensure,
  }
  service{$service:
    ensure => $service_ensure,
    enable => $enable,
  }
}
