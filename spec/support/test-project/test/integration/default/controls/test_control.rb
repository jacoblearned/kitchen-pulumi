# frozen_string_literal: true

control 'test_control' do
  describe 'bucket name input and outputs match without prefix' do
    subject do
      input('bucketName')
    end

    it { should eq input('test-project:bucket_name') }
  end

  describe 'bucket_name input and outputs match' do
    subject do
      input('output_bucketName')
    end

    it { should eq input('input_test-project:bucket_name') }
  end
end
