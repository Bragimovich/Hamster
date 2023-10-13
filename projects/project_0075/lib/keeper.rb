# frozen_string_literal: true

require 'yaml'
require_relative '../models/building_permits_by_county'
require_relative '../models/building_permits_by_county_runs'

class BuildingPermitsKeeper

# save_to_table simply inserts the given array into it's corresponding table.

  def save_to_table(data_ary)
    building_permits = BuildingPermits.new
    split_ary = data_ary.size
    split_ary = split_ary / 2
    BuildingPermits.insert_all(data_ary[0..split_ary].compact)
    BuildingPermits.insert_all(data_ary[(split_ary + 1)..-1].compact)
  end

  def check_for_updates(link)
    BuildingPermits.where(link: "#{link}")
  end


  def mark_store_as_started
    last_run = BuildingPermitsRuns.last
    BuildingPermitsRuns.find(last_run.id).update(status: 'store started')
  end

  def mark_store_as_finished
    last_run = BuildingPermitsRuns.last
    BuildingPermitsRuns.find(last_run.id).update(status: 'store finished')
  end

  def mark_as_started
    BuildingPermitsRuns.create
    last_run = BuildingPermitsRuns.last
    BuildingPermitsRuns.find(last_run.id).update(status: 'download started')
  end
  
  def mark_as_finished
    last_run = BuildingPermitsRuns.last
    BuildingPermitsRuns.find(last_run.id).update(status: 'download finished')
  end
end
