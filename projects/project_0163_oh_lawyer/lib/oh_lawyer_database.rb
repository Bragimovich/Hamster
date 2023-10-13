# frozen_string_literal: true


def insert_all(lawyers)
  OhioLawyerStatus.insert_all(lawyers)
end

def get_existing_bar_numbers(bar_numbers)
  existing_bar_number_array = []
  lawyers = OhioLawyerStatus.where(bar_number:bar_numbers)
  lawyers.each {|row| existing_bar_number_array.push(row[:bar_number])}
  existing_bar_number_array
end

def get_md5_hash(bar_numbers)
  existing_md5_hash = []
  lawyers = OhioLawyerStatus.where(bar_number:bar_numbers)
  lawyers.each {|row| existing_md5_hash.push(row[:md5_hash])}
  existing_md5_hash
end

def put_new_touched_id(md5_hash_array, run_id)
  lawyers = OhioLawyerStatus.where(md5_hash:md5_hash_array)
  lawyers.update_all(touched_run_id:run_id, deleted:0)
end

def deleted_for_not_equal_run_id(run_id)
  lawyers = OhioLawyerStatus.where.not(touched_run_id:run_id)
  lawyers.update_all(deleted:1)
end