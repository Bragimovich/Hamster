# frozen_string_literal: true

require_relative '../lib/gasbuddy_runs'
require_relative '../models/gasbuddy_gas_stations_runs'

class GasBuddyKeeper < Hamster::Harvester

  CHUNK = 500

  def initialize
    super
    @runner = RunManager.new(GasBuddyRuns)
  end

  def finished?
    ['finished', 'processing'].include? @runner.status
  end

  def start
    @runner.start if @runner.status != 'processing'
    @runner.status = 'store started'
  end

  def restart
    @runner.status = 'store restarted'
  end

  def finish
    @runner.finish
  end

  def run_id
    @runner.run_id
  end

  def list_all_zips(model)
    model.pluck(:zip_char).sort
  end

  def collect_prestored_zip_md5(model)
    model.where(run_id: @runner.run_id).pluck(:md5_hash).to_set
  end

  def collect_prestored_station_id(model)
    model.where(deleted: 0, touched_run_id: @runner.run_id).pluck(:station_id).to_set
  end

  def list_stations_md5_by_zip(zip, model)
    model.where(deleted: 0, zip_searched: zip).pluck(:md5_hash).to_set
  end

  def list_prices_md5_by_zip(zip, model)
    model.where(deleted: 0, zip_searched: zip).pluck(:md5_hash).to_set
  end

  def store_all(records, model)
    records.each do |record|
      record[:run_id] = @runner.run_id
      record[:touched_run_id] = @runner.run_id
    end
    records.each_slice(CHUNK) do |chunk|
      model.insert_all(chunk)
    end
  end

  def store(record, model)
    record[:run_id] = @runner.run_id
    record[:touched_run_id] = @runner.run_id
    model.insert record
  end

  def update_touched_run_id(model, md5_hash)
      model.where(deleted: 0, md5_hash: md5_hash).update_all(touched_run_id: @runner.run_id)
  end

  def update_all_touched_run_id(model, unchanged_md5)
    unchanged_md5.each_slice(CHUNK) do |md5_chunk|
      model.where(md5_hash: md5_chunk).update_all(touched_run_id: @runner.run_id)
    end
  end

  def update_deleted_status(model)
    model.where(deleted: 0).where.not(touched_run_id: @runner.run_id).update_all(deleted: 1)
  end

  def update_zip_data(zip, new_md5, model)
    # model.where(zip_searched: zip).update_all(run_id: @runner.run_id, md5_hash: new_md5)
    model.find_or_create_by(zip_searched: zip).update(run_id: @runner.run_id, md5_hash: new_md5)
  end

  def last_zip_recorded(model)
    model.where(run_id: @runner.run_id).pluck(:zip_searched).sort.last
  end

end
