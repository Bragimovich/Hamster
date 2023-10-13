# Command to run this test: rspec --format documentation spec/lib/hamster/decrypt.rb

# These commands must work before running this file:

# rspec --format documentation spec/lib/hamster/generate_key.rb
# rspec --format documentation spec/lib/hamster/encrypt.rb

require_relative '../../../hamster.rb'

RSpec.describe Hamster do
  describe "#decrypt" do
    before(:each) do
      @file_contents = "hello world"
      @encrypted_file_path = "testfile.txt.enc"
    end
    it "decrypts secrets/testfile.txt.enc from previous encrypt and writes it to decrypted file (removing .enc)" do
      # Call the decrypt method with the sample encrypted file as input
      File.write('testfile.txt', @file_contents)
      File.write('testfile_named.txt', @file_contents)
      Hamster.wakeup({encrypt: 'testfile.txt'})
      Hamster.wakeup({generate_key: "test_key_rspec"})
      Hamster.wakeup({encrypt: 'testfile_named.txt', with: 'test_key_rspec'})
      File.delete("testfile.txt") if File.exist?("testfile.txt")
      File.delete("testfile_named.txt") if File.exist?("testfile_named.txt")
      Hamster.wakeup({ decrypt: @encrypted_file_path })

      # Check that the decrypted file was created and contains the original data
      decrypted_file_path = "testfile.txt"
      expect(File.exist?(decrypted_file_path)).to be true
      expect(File.read(decrypted_file_path)).to eq(@file_contents)

      # Cleanup
      File.delete("testfile.txt") if File.exist?("testfile.txt")
    end
    it "decrypts secrets/testfile.txt.enc from previous encrypt and writes it to decrypted file (removing .enc) - using --to option" do
      Hamster.wakeup({ decrypt: @encrypted_file_path, to: "path_to_test/testfile.txt" })

      # Check that the decrypted file was created and contains the original data
      decrypted_file_path = "path_to_test/testfile.txt"
      expect(File.exist?(decrypted_file_path)).to be true
      expect(File.read(decrypted_file_path)).to eq(@file_contents)

      # Cleanup
      File.delete("secrets/#{@encrypted_file_path}") if File.exist?("secrets/#{@encrypted_file_path}")
      File.delete(decrypted_file_path) if File.exist?(decrypted_file_path)
      Dir.delete("path_to_test") if Dir.exist?('path_to_test')
    end
    it "decrypts secrets/testfile.txt.enc from previous encrypt and writes it to decrypted file (removing .enc) - using --with option" do
      # Create a sample encrypted file with some contents
      encrypted_file_path = "testfile_named.txt.enc"

      Hamster.wakeup({ decrypt: encrypted_file_path, with: "test_key_rspec" })

      # Check that the decrypted file was created and contains the original data
      decrypted_file_path = "testfile_named.txt"
      expect(File.exist?(decrypted_file_path)).to be true
      expect(File.read(decrypted_file_path)).to eq(@file_contents)

      # Cleanup
      File.delete("secrets/#{encrypted_file_path}") if File.exist?("secrets/#{encrypted_file_path}")
      File.delete(decrypted_file_path) if File.exist?(decrypted_file_path)
      File.delete("secrets/test_key_rspec.key")
    end
  end
end