# Command to run this test: rspec --format documentation spec/lib/hamster/encrypt.rb

# This command must work before running this file:

# rspec --format documentation spec/lib/hamster/generate_key.rb

require_relative '../../../hamster.rb'

RSpec.describe Hamster do
  describe "#encrypt" do
    before(:each) do
      @file_contents = "hello world"
      @file_path = "testfile.txt"
      File.write(@file_path, @file_contents)
    end
    after(:each) do
      File.delete(@file_path) if File.exist?(@file_path)
    end
    it "encrypts a testfile.txt file and writes it to an encrypted (.enc) file using master.key (default)" do
      # Call the encrypt method with the sample file as input
      Hamster.wakeup({generate_key: "test_key_rspec"})
      Hamster.wakeup({encrypt: @file_path})

      # Check that the encrypted file was created and contains some data
      encrypted_file_path = "secrets/#{@file_path}.enc"
      expect(File.exist?(encrypted_file_path)).to be true
      expect(File.read(encrypted_file_path)).not_to be_empty
      File.delete(encrypted_file_path) if File.exist?(encrypted_file_path)
    end
    context "when destination file exists" do
      it "when user confirms overwrite returns the destination file path and overwrites the file" do
        destination_file_path = "secrets/testfile.txt.enc"
        Hamster.wakeup({encrypt: @file_path})
        encrypted_file_before = File.read(destination_file_path)
        allow(IO).to receive(:console).and_return(StringIO.new("y"))
        Hamster.wakeup({encrypt: @file_path})
        expect(File.exist?(destination_file_path)).to be true
        expect(File.read(destination_file_path)).not_to eq(encrypted_file_before)
      end
      it "returns 'Command canceled.' and does not overwrite the file when user cancels overwrite" do
        destination_file_path = "secrets/testfile.txt.enc"
        encrypted_file_before = File.read(destination_file_path)
          
        # Stub IO.console
        allow(IO).to receive(:console).and_return(StringIO.new("n"))
    
        # Run the method
        expect {
          begin
            Hamster.wakeup({encrypt: @file_path})
          rescue SystemExit
          end
        }.to output(/Command canceled\./).to_stdout
  
        # Check that the file was not overwritten
        expect(File.exist?(destination_file_path)).to be true
        expect(File.read(destination_file_path)).to eq(encrypted_file_before)
      end

      it "returns 'Invalid input. Command canceled.' and does not overwrite the file when user inputs invalid reponse 3 times when prompted" do
        destination_file_path = "secrets/testfile.txt.enc"
        encrypted_file_before = File.read(destination_file_path)


        allow(IO).to receive(:console).and_return(StringIO.new("s"))
        # Run the method
        expect {
          begin
            Hamster.wakeup({encrypt: @file_path})
          rescue SystemExit
          end
        }.to output(/Invalid input. Command canceled\./).to_stdout
  
        # Check that the file was not overwritten
        expect(File.exist?(destination_file_path)).to be true
        expect(File.read(destination_file_path)).to eq(encrypted_file_before)
        File.delete(destination_file_path) if File.exist?(destination_file_path)
      end
    end
    it "encrypts a testfile.txt file and writes it to an encrypted (.enc) file using a named key" do
      # Create a sample file with some contents
      file_path = "testfile_named.txt"
      File.write(file_path, @file_contents)
      key_name = "test_key_rspec"

      # Call the encrypt method with the sample file as input and a named key
      Hamster.wakeup({encrypt: file_path, with: key_name})

      # Check that the encrypted file was created and contains some data
      File.delete(file_path) if File.exist?(file_path)
      encrypted_file_path = "secrets/#{file_path}.enc"
      expect(File.exist?(encrypted_file_path)).to be true
      expect(File.read(encrypted_file_path)).not_to be_empty
      File.delete('secrets/test_key_rspec.key') if File.exist?("secrets/test_key_rspec.key")
      File.delete(encrypted_file_path) if File.exist?(encrypted_file_path)
    end
  end
end