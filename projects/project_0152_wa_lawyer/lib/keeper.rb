require_relative '../models/washington_db_model'

class Keeper
  def initialize
    @run_object = RunId.new(WashingtonLawyerStatusRuns)
    @run_id = @run_object.run_id
  end

  def store(hash)
    hash = replace_empty_strings_with_nil(hash)
    hash = add_md5_hash(hash)
    check = WashingtonLawyerStatus.where(link: hash[:link]).as_json.first
    if check && check['md5_hash'] == hash['md5_hash']
      WashingtonLawyerStatus.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      WashingtonLawyerStatus.mark_deleted(check['id'])
      WashingtonLawyerStatus.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      WashingtonLawyerStatus.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def add_md5_hash(hash)
    hash['md5_hash'] = make_md5(hash)
    hash
  end

  def make_md5(news_hash)
    all_values_str = ''
    columns = %i[bar_number name link law_firm_name law_firm_address type registration_status phone eligibility law_firm_website]
    columns.each do |key|
      if news_hash[key].nil?
        all_values_str = all_values_str + news_hash[key.to_s].to_s
      else
        all_values_str = all_values_str + news_hash[key].to_s
      end
    end
    Digest::MD5.hexdigest all_values_str
  end

  def replace_empty_strings_with_nil(hash)
    new_hash = {}
    hash.each do |key, value|
      new_hash[key] = value.presence || nil
    end
    new_hash
  end 

  def finish
    @run_object.finish
  end
end