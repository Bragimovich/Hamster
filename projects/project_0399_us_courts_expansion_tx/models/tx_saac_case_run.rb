# frozen_string_literal: true

# require_relative '../config/database_config'

class TxSaacCaseRun < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  # your code if necessary
end
