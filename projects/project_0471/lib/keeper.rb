require_relative '../models/ri_court_rijudiciary'
require_relative '../models/ri_court_rijudiciary_runs'
class Keeper
  attr_reader :run_id

  def initialize
    super
    @run_object = RunId.new(RiCourtRijudiciaryRuns)
    @run_id = @run_object.run_id
  end

  def store(hash)
    # removing nil values in hash
    hash.compact!
    check = RiCourtRijudiciary.where(data_source_url: hash['data_source_url']).as_json.first
    if check && check['md5_hash'] == hash['md5_hash']
      RiCourtRijudiciary.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      RiCourtRijudiciary.mark_deleted(check['id'])
      RiCourtRijudiciary.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      RiCourtRijudiciary.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def finish
    @run_object.finish
  end
end