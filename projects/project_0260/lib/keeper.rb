require_relative '../models/ma_public'
require_relative '../models/ma_public_runs'

class Keeper
  def initialize
    @run_object = RunId.new(MaPublicRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def already_inserted_md5
    MaPublic.pluck(:md5_hash)
  end

  def insert_records(data_array)
    dump_array = []
    data_array.each do |record|
      dump_array << record
      if dump_array.count == 5000
        MaPublic.insert_all(dump_array)
        dump_array = []
      end
    end
    MaPublic.insert_all(dump_array) unless dump_array.empty?
  end

  def finish
    @run_object.finish
  end
end
