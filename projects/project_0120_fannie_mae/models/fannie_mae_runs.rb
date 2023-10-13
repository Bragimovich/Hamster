# frozen_string_literal: true

# require_relative '../config/database_config'

class FannieMaeRuns < ActiveRecord::Base
  establish_connection(Storage.use(host: :db02, db: :press_releases))
  # your code if necessary
end
