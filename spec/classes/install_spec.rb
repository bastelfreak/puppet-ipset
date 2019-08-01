# frozen_string_literal: true

require 'spec_helper'

def check_base
  it do
    is_expected.to contain_class('ipset::params')
    is_expected.to contain_package('ipset').only_with(
      ensure: 'latest',
      alias: 'ipset'
    )
    is_expected.to contain_file('/etc/sysconfig/ipset.d')
      .only_with(ensure: 'directory')
  end
end

def check_ipsets
  it do
    %w[init sync].each do |script|
      is_expected.to contain_file("/usr/local/sbin/ipset_#{script}")
        .only_with(ensure: 'file', owner: 'root', group: 'root', mode: '0754',
                   source: "puppet:///modules/ipset/ipset_#{script}")
    end
  end
end

def check_rhel6_upstart_conf
  it do
    is_expected.to contain_file('/etc/init/ipset.conf').with(
      ensure: 'file', owner: 'root', group: 'root', mode: '0644',
      content: <<~CONFIG
        task

        exec /usr/local/sbin/ipset_init -c "/etc/sysconfig/ipset.d"

        # run before all sysv-init scripts, where the firewall (iptables) is
        start on starting rc RUNLEVEL=[2345]
      CONFIG
    ).that_requires('Exec[ipset_disable_distro]')
  end
end

describe 'ipset::install' do
  context 'RedHat 6' do
    let :facts do
      { os: { family: 'RedHat', release: { major: '6' } } }
    end

    check_base
    check_ipsets
    check_rhel6_upstart_conf

    it do
      is_expected.to contain_package('libmnl').only_with(
        ensure: 'installed',
        before: 'Package[ipset]'
      )
      is_expected.to contain_exec('ipset_disable_distro').with(
        # rubocop:disable Metrics/LineLength
        command: "/bin/bash -c '/etc/init.d/ipset stop && /sbin/chkconfig ipset off'",
        unless: "/bin/bash -c '/sbin/chkconfig | /bin/grep ipset | /bin/grep -qv :on'",
        # rubocop:enable Metrics/LineLength
        require: 'Package[ipset]'
      )
      is_expected.to contain_service('ipset_enable_upstart').only_with(
        name: 'ipset',
        enable: true,
        provider: 'upstart'
      ).that_subscribes_to('File[/etc/init/ipset.conf]')
    end
  end
end

# rubocop:disable  Metrics/MethodLength
def check_rhel7_systemd_unit(firewall_service)
  it do
    is_expected.to contain_file('/usr/lib/systemd/system/ipset.service')
      .with(
        ensure: 'file',
        owner: 'root',
        group: 'root',
        mode: '0644',
        content: <<~CONFIG
          [Unit]
          Description=define and fill-in ipsets
          Before=#{firewall_service}.service

          [Service]
          Type=oneshot
          RemainAfterExit=yes
          ExecStart=/usr/local/sbin/ipset_init -c "/etc/sysconfig/ipset.d"

          [Install]
          WantedBy=basic.target
        CONFIG
      )
  end
end
# rubocop:enable  Metrics/MethodLength

describe 'ipset::install' do
  %w[iptables firewalld].each do |firewall_service|
    context "RedHat 7 - #{firewall_service}" do
      let(:pre_condition) do
        <<~CONDITION
          class { '::ipset::params':
            use_firewall_service => '#{firewall_service}',
          }
        CONDITION
      end
      let :facts do
        {
          os: {
            family: 'RedHat',
            release: {
              major: 7
            }
          }
        }
      end
      check_base
      check_ipsets
      check_rhel7_systemd_unit(firewall_service)

      it do
        is_expected.to contain_service('ipset').only_with(
          ensure: 'running',
          enable: true,
          require: 'File[/usr/local/sbin/ipset_init]'
        ).that_subscribes_to('File[/usr/lib/systemd/system/ipset.service]')
      end
    end
  end
end
