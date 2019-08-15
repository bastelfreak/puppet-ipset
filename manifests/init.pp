class ipset (
  String[1] $package,
  String[1] $service,
  Stdlib::Ensure::Service $service_ensure,
  Boolean $enable,
  Enum['present', 'absent', 'latest'] $package_ensure,
){
  package{$ipset::package:
    ensure => $package_ensure,
  }
  service{$service:
    ensure => $service_ensure,
    enable => $enable,
  }
}
