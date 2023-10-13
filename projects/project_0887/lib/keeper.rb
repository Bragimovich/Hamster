# frozen_string_literal: true
require_relative '../models/ny_monroe_runs'
require_relative '../models/ny_monroe_inmates'
require_relative '../models/ny_monroe_arrests'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NyMonroeRuns)
    @run_id = @run_object.run_id
  end

  def insert_data(data_inmates)
    data_inmates = data_inmates.map {|hash| add_run_id(hash)}
    md5_hash = data_inmates.map {|hash| hash.slice(:md5_hash)}.map(&:values).flatten
    inmates = data_inmates.map {|hash| hash.slice(:last_name, :first_name, :last_name, :full_name, :md5_hash, :run_id, :data_source_url)}
    NyMonroeInmates.insert_all(inmates)
    NyMonroeInmates.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)
    Hamster.close_connection(NyMonroeInmates)

    arrests = data_inmates.each do |hash|
      hash[:inmate_id] = NyMonroeInmates.where(md5_hash:hash[:md5_hash]).first.id
    end
    arrests = arrests.map {|hash| hash.slice(:inmate_id, :booking_date, :booking_number, :status, :md5_hash, :run_id, :data_source_url)}
    NyMonroeArrests.insert_all(arrests)
    NyMonroeArrests.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)
    Hamster.close_connection(NyMonroeArrests)
  end

  def update_inmate_status
    NyMonroeInmates.where.not(touched_run_id:run_id).update_all(deleted:1)
    Hamster.close_connection(NyMonroeInmates)
    NyMonroeArrests.where.not(touched_run_id:run_id).where(released_date:nil).update_all(status:"Released",released_date:released_date)
    Hamster.close_connection(NyMonroeArrests)
  end

  def released_date
    Date.today.to_s
  end

  def add_run_id(hash)
    hash[:run_id] = @run_id
    hash
  end

  def finish
    @run_object.finish
  end
end
