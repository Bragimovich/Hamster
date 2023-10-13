# frozen_string_literal: true


module Hamster
  private

  def self.generate_key
    check_key = check_key_name

    return puts check_key if check_key == "Invalid input. Command canceled."

    if check_key && check_key != "canceled"
      key_path = "secrets/#{@arguments[:generate_key]}.key"
      begin
        FileUtils.mkdir_p("secrets")
      rescue
        raise "Error attempting to create directory 'secrets'."
      end

      begin
        File.write(key_path, ActiveSupport::EncryptedFile.generate_key)
      rescue
        raise "Error writing to file '#{key_path}'."
      end

      begin
        if !File.foreach('.gitignore').any? { |line| line.chomp == key_path }
          File.open('.gitignore', 'a') do |f|
            f.puts(key_path)
          end
        end
      rescue
        raise "Error adding file path to '.gitignore'."
      end
      puts "Key '#{key_path}' created."
    else
      if check_key=="canceled"
        puts "Canceled."
      else
        raise "Invalid key name, must only name of file like 'secret'."
      end
    end
  end
end