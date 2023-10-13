# frozen_string_literal: true


def insert_all_by_location(taxes)
  IllinoisByLocation.insert_all(taxes)
end

def insert_all_tax_type_totals(taxes)
  IllinoisTaxTypeTotals.insert_all(taxes)
end

def get_date_in_db
  IllinoisByLocation.select(:voucher_date).distinct.map { |row| row.voucher_date }
end


def get_md5_hash(bar_numbers)
  existing_md5_hash = []
  lawyers = IllinoisByLocation.where(bar_number:bar_numbers)
  lawyers.each {|row| existing_md5_hash.push(row[:md5_hash])}
  existing_md5_hash
end

def put_new_touched_id(md5_hash_array, run_id)
  lawyers = IllinoisByLocation.where(md5_hash:md5_hash_array)
  lawyers.update_all(touched_run_id:run_id, deleted:0)
end

def deleted_for_not_equal_run_id(run_id)
  lawyers = IllinoisByLocation.where.not(touched_run_id:run_id)
  lawyers.update_all(deleted:1)
end