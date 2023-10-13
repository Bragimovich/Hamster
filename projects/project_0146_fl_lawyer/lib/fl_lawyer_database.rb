# frozen_string_literal: true

def insert_all_each(lawyers)
  FloridaLawyerStatus.insert_all(lawyers)
  return 0
  lawyers.each do |lawyer|
    begin
      FloridaLawyerStatus.insert(lawyer)
      # law = FloridaLawyerStatus.new do |i|
      #   i.bar_number          = lawyer[:bar_number]
      #   i.name                = lawyer[:name]
      #   i.link                = lawyer[:link]
      #   i.law_firm_name       = lawyer[:law_firm_name]
      #   i.law_firm_address    = lawyer[:law_firm_address]
      #   i.law_firm_zip        = lawyer[:law_firm_zip]
      #   i.law_firm_county     = lawyer[:law_firm_county]
      #   i.law_firm_state      = lawyer[:law_firm_state]
      #   i.phone               = lawyer[:phone]
      #   i.email               = lawyer[:email]
      #   i.date_admitted       = lawyer[:date_admitted]
      #   i.sections            = lawyer[:sections]
      #   i.registration_status = lawyer[:registration_status]
      #   i.eligibility         = lawyer[:eligibility]
      #   i.law_school          = lawyer[:law_school]
      #   i.md5_hash            = lawyer[:md5_hash]
      #   i.run_id              = lawyer[:run_id]
      #   i.touched_run_id      = lawyer[:touched_run_id]
      # end
      #law.save
    rescue => e
      p e
      File.open("#{storehouse}/problem_lawyers", 'a') { |file| file.write("#{e}:#{lawyer[:link]}\n") }
      next
    end

  end
end


def insert_all(lawyers)
  FloridaLawyerStatus.insert_all(lawyers)
end


def florida_db_reconnect
  FloridaLawyerStatus.connection.reconnect!
end

def existing_bar_number(bar_numbers)
  existing_bar_number_array = []
  FloridaLawyerStatus.where(bar_number:bar_numbers).each {|row| existing_bar_number_array.push(row[:bar_number])}
  existing_bar_number_array
end

def get_md5_hash(bar_numbers)
  existing_md5_hash = []
  lawyers = FloridaLawyerStatus.where(bar_number:bar_numbers)
  lawyers.each {|row| existing_md5_hash.push(row[:md5_hash])}
  existing_md5_hash
end

def put_new_touched_id(md5_hash_array, run_id)
  lawyers = FloridaLawyerStatus.where(md5_hash:md5_hash_array)
  lawyers.update_all(touched_run_id:run_id, deleted:0)
end

def deleted_for_not_equal_run_id(run_id)
  lawyers = FloridaLawyerStatus.where.not(touched_run_id:run_id)
  lawyers.update_all(deleted:1)
end

def mark_deleted(md5_hash_array)
  lawyers = FloridaLawyerStatus.where(md5_hash:md5_hash_array)
  lawyers.update_all(deleted:1)
end

def get_inupdated_lawyers(run_id, limit:100)
  FloridaLawyerStatus.where(deleted:0).where.not(touched_run_id:run_id).limit(limit)
end