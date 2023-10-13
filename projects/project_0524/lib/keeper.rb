require_relative '../models/inspector_runs'
require_relative '../models/inspector_general_reports'
require_relative '../models/inspector_general_reports_locations'

class Keeper

  def initialize
    @run_object = RunId.new(InspectorRuns)
    @run_id = @run_object.run_id
  end

  def store_report_locations(hash)
    hash = HashWithIndifferentAccess.new(hash)
    hash = add_md5_hash(hash)
    check = InspectorGeneralReportsLocations.where(md5_hash: hash['md5_hash']).as_json.first
    unless check.present?
      InspectorGeneralReportsLocations.insert(hash)
    end
  end

  def get_report_id(data_source_url)
    InspectorGeneralReports.where(data_source_url: data_source_url, deleted: 0)&.first&.id
  end

  def store_reports(hash)
    hash = HashWithIndifferentAccess.new(hash)
    hash = add_md5_hash(hash)
    check = InspectorGeneralReports.where(data_source_url: hash['data_source_url'], deleted: 0).as_json.first
    if check && check['md5_hash'] == hash[:md5_hash]
      InspectorGeneralReports.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      InspectorGeneralReports.mark_deleted(check['id'])
      InspectorGeneralReports.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      InspectorGeneralReports.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end
  
  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end

  def finish
    @run_object.finish
  end

end