# frozen_string_literal: true

control 'integration test' do
  describe http(input('endpoint')) do
    its('body') { should eq input('kitchen-pulumi-azure-functions:api_response') }
  end
end
