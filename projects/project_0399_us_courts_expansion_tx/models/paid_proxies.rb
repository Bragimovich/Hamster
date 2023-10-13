# frozen_string_literal: true

# require_relative '../config/database_config'

class PaidProxies < ActiveRecord::Base
  establish_connection(Storage.use(host: :db02, db: :hle_resources))
  # your code if necessary
end
