require_relative '../models/mo_bar_mobar_org'
require_relative '../models/mo_bar_runs'
require_relative '../models/all_cities'
class Keeper
  attr_accessor :all_cities
  def initialize
    @run_object = RunId.new(MooBarRuns)
    @run_id = @run_object.run_id
    @all_cities = AllCities.pluck(:short_name).uniq
  end

  def store(hash)
    hash = HashWithIndifferentAccess.new(hash)
    hash = add_md5_hash(hash)
    check = MoBarMobarOrg.where(data_source_url: hash['data_source_url'], deleted: 0).as_json.first
    if check && check['md5_hash'] == hash[:md5_hash]
      MoBarMobarOrg.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      MoBarMobarOrg.mark_deleted(check['id'])
      MoBarMobarOrg.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      MoBarMobarOrg.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end
  
  def finish
    @run_object.finish
  end
  
  private

  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end
end