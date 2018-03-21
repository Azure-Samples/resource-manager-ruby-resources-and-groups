require 'spec_helper'
require_relative '../example'

describe 'Resource Manager Example' do
  let(:subcription_id) { 'subscription_id' }

  context 'without credential environment vars set' do
    it 'should raise error that the Tenant id was not specified' do
      ClimateControl.modify AZURE_SUBSCRIPTION_ID: subcription_id, AZURE_TENANT_ID: nil, AZURE_CLIENT_ID: nil, AZURE_CLIENT_SECRET: nil do
        expect {
          run_example
        }.to raise_error(ArgumentError, 'Tenant id cannot be nil')
      end
    end
  end

end