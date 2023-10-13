# frozen_string_literal: true

class ZipcodeData < ActiveRecord::Base
  establish_connection(Storage.use(host: :db02, db: :hle_resources))
end
