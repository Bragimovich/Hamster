# frozen_string_literal: true

class CmsGovCovidVaxRate < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
end


