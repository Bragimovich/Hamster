# frozen_string_literal: true

# require_relative '../config/database_config'

class KansasCampaignFinanceContributors < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :usa_raw))
  # your code if necessary
end
