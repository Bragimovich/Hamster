# frozen_string_literal: true

class MinnesotaBusinessLicenseTrademarkBaseData < ActiveRecord::Base
  establish_connection(Storage[host: :db13, db: :usa_raw])
  include Hamster::Granary
end
