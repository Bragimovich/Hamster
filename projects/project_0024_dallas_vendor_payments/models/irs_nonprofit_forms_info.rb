# frozen_string_literal: true

class IrsNonprofitFormsInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])

  def self.last_updated(form)
    r = self.where({form_type: form}).as_json.first
    r['last_data_source_update'] if r
  end

  def self.set_last_updated(form, new_date)
    self.where({form_type: form}).limit(1).update_all({last_data_source_update: new_date})
  end
end
