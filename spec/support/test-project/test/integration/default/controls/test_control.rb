# frozen_string_literal: true

control 'test_control' do
  describe 'bucket name input and outputs match without prefix' do
    subject do
      attribute('bucketName')
    end

    it { should eq attribute('test-project:bucket_name') }
  end

  describe 'bucket_name input and outputs match' do
    subject do
      attribute('output_bucketName')
    end

    it { should eq attribute('input_test-project:bucket_name') }
  end
end
