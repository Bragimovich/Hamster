# frozen_string_literal: true


module Hamster
  private

  def self.decrypt
    options = check_encrypt_decrypt_options

    puts "Decrypting file 'secrets/#{@arguments[:decrypt]}' to '#{options[:to]}'..."
    decrypt_file(options)
  end
end