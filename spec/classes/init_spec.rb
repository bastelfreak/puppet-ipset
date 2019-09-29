require 'spec_helper'

describe 'ipset' do
  let :node do
    'agent.example.com'
  end

  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts.merge({systemd: true})
      end
      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('ipset') }
        it { is_expected.to contain_file('/usr/local/bin/ipset_init') }
        it { is_expected.to contain_file('/usr/local/bin/ipset_sync') }
        it { is_expected.to contain_systemd__unit_file('ipset.service') }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_package('ipset-service') }
          it { is_expected.not_to contain_file('/etc/ipset.d/') }
          it { is_expected.to contain_file('/etc/sysconfig/ipset.d') }
        else
          it { is_expected.not_to contain_package('ipset-service') }
          it { is_expected.to contain_file('/etc/ipset.d/') }
          it { is_expected.not_to contain_file('/etc/sysconfig/ipset.d') }
        end
      end
    end
  end
end
