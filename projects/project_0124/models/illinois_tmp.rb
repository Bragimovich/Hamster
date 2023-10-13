# frozen_string_literal: true
require 'strip_attributes'
# db01.lawyer_status.Illinois
class Illinois < ActiveRecord::Base
  strip_attributes
  self.table_name = 'Illinois_tmp'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status])

  before_create :gen_md5_hash
  before_update :gen_md5_hash

  def gen_md5_hash
    str = ""
    self.attributes.map do |name, value|
      col_name = name
      next if col_name.match?(/^(id|run_id|created_at|md5_hash|updated_at|touched_run_id)/)
      str += value.to_s
    end
    self.md5_hash = Digest::MD5.hexdigest(str)
  end
end