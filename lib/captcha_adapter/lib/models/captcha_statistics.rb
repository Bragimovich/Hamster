module Hamster
  module CaptchaAdapter
    class CaptchaStatistics < ActiveRecord::Base
      storage = Storage.use(host: :db02, db: :hle_resources)
      establish_connection(storage) if storage
      self.table_name = 'captcha_statistics'
      # def add_md5_hash(hash)
      #   hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
      #   hash
      # end
    end
  end
end



