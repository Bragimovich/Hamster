# frozen_string_literal: true


module Hamster
  private

  def self.encrypt
    options = check_encrypt_decrypt_options

    puts "Encrypting file '#{@arguments[:encrypt].sub(/^\//,'')}' to 'secrets/#{File.basename(@arguments[:encrypt])}.enc'..."
    encrypt_file(options)
  end
end
