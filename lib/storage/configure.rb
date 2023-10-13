# frozen_string_literal: true

class Storage
  private

  def self.configure
    parse_files = Dir.entries('secrets').select{|el| el =~ /\.yml\.enc/}
    required_files = ['config.yml.enc','credentials.yml.enc']
    missing_files = required_files - parse_files
    raise "Missing required file(s): #{missing_files.join(', ')}" unless missing_files.empty?

    files = {}
    parse_files.each do |file_name|
      begin
        parsed_file = File.read("secrets/#{file_name}")
        secret_key = File.read('secrets/master.key').strip
        encryptor = ActiveSupport::MessageEncryptor.new(secret_key)
        decrypted = encryptor.decrypt_and_verify(parsed_file)
      rescue => e
        raise "You are missing the master.key file in secrets, please download it and place it in the secrets/"\
        " folder, you can find it here - https://locallabs.slack.com/archives/G01CY84KMT6/p1682986459429189" if e.message=="No"\
        " such file or directory @ rb_sysopen - secrets/master.key"
        next
      else
        decrypted_yaml = <<-YAML
          #{decrypted}
        YAML
        files.deep_merge!(YAML.safe_load(decrypted_yaml.strip, symbolize_names: true))
        files.deep_merge!(YAML.safe_load(decrypted_yaml.strip))
      end
    end
    # puts files
    required_keys = %i[databases dir_names messenger server browser aws captcha google_drive business_analytics]
    missing_creds = required_keys - files.keys
    raise "Missing required configuration(s)/credential(s) in 'secrets/config.yml.enc' or 'secrets/credentials.yml.enc'"\
    ": #{missing_creds.join(', ')}" unless missing_creds.empty?

    files.each do |key, value|
      value = Hashie::Mash.new(value)
      instance_variable_set("@#{key}", value)
      value&.each do |k, v|
        define_method(k) { v }
      end if key.is_a?(Symbol)
    end
  end
end