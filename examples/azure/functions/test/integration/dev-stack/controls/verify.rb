control "integration test" do
  describe http(input('endpoint')) do
    its ('body') { should eq 'integration test'}
  end
end
