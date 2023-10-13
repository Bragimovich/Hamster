# frozen_string_literal: true

def insert_all(lawyers)
  TaxExempt.insert_all(lawyers)
end

def get_existing_ein(ein, run_id=0)
  existing_ein_array = []
  tax_exp = TaxExempt.where(ein:ein)
  tax_exp.each {|row| existing_ein_array.push(row[:ein])}
  existing_ein_array
end

def get_md5_hash(ein, run_id=0)
  existing_md5_hash = []
  tax_exp = TaxExempt.where(ein:ein)
  tax_exp.each {|row| existing_md5_hash.push(row[:md5_hash])}
  existing_md5_hash
end

def put_new_touched_id(md5_hash_array, run_id)
  lawyers = TaxExempt.where(md5_hash:md5_hash_array)
  lawyers.update_all(touched_run_id:run_id, deleted:0)
end

def deleted_for_not_equal_run_id(run_id)
  tax_exp = TaxExempt.where.not(touched_run_id:run_id)
  tax_exp.update_all(deleted:1)
end