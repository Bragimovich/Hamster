# Command to run this test: rspec --format documentation spec/lib/hamster/generate_key.rb

# This file must be working before running the following commands:

# rspec --format documentation spec/lib/hamster/decrypt.rb
# rspec --format documentation spec/lib/hamster/encrypt.rb

require_relative '../../../hamster.rb'

RSpec.describe Hamster do
  describe "#generate_key" do
    it "generates a test_key_rspec.key file in secrets" do
      Hamster.wakeup({generate_key: "test_key_rspec"})

      # Check that the encrypted file was created and contains some data
      expect(File.exist?("secrets/test_key_rspec.key")).to be true
      expect(File.read("secrets/test_key_rspec.key")).not_to be_empty
      File.delete("secrets/test_key_rspec.key")
    end
  end
end