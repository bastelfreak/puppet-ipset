require 'spec_helper'

describe 'ipset' do
  let :node do
    'agent.example.com'
  end

  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts
      end
      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('ipset') }
        it { is_expected.to contain_service('ipset') }

        if facts[:os]['family'] == 'RedHat'
          it { is_expected.to contain_package('ipset-service') }
        else
          it { is_expected.not_to contain_package('ipset-service') }
        end
      end
    end
  end
end
