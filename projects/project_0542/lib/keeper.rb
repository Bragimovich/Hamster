require_relative '../models/az_bar_azbar_org'
require_relative '../models/az_bar_azbar_org_runs'
class Keeper

  def initialize
    super
    @count = 0
    @run_id = run.run_id
  end

  attr_reader :run_id, :count

  def status=(new_status)
    run.status = new_status
  end

  def finish
    run.finish
  end

  def store_lawyers(lawyers)
    lawyers.each do |lawyer|
      lawyer[:run_id]         = run_id
      lawyer[:touched_run_id] = run_id
      current_bar_number      = lawyer[:bar_number]
      lawyer_db               = AzBarAzbarOrg.find_by(bar_number: current_bar_number, deleted: 0)
      AzBarAzbarOrg.store(lawyer) unless lawyer_db
      next unless lawyer_db

      if lawyer_db[:md5_hash] == lawyer[:md5_hash]
        lawyer_db.update(touched_run_id: run_id)
      else
        lawyer_db.update(deleted: 1)
        AzBarAzbarOrg.store(lawyer)
      end
      @count += 1
    end
  end

  private

  def run
    RunId.new(AzBarAzbarOrgRun)
  end
end
