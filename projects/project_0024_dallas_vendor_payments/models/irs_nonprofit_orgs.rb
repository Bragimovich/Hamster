# frozen_string_literal: true

class Covid19Vaccination < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])

  def self.insert_ignore_into(values)
    self.create!(values)
  rescue ActiveRecord::RecordNotUnique
    # To prevent not unique error
  end

  def self.col_names
    hash = {}
    self.columns.map { |column| hash[column.name.to_sym] = nil }
    hash
  end
end
