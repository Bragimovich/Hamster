# frozen_string_literal: true

require_relative '../models/ct_court__jud_ct_gov'
require_relative '../models/runs'

class  Keeper < Hamster::Harvester
  attr_writer :data_arr

  def initialize(options)
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id
  end

  def store_data
    unless @data_arr.nil? || @data_arr.empty?
      main_arr = []
      @data_arr.each do |hash|
        source_url =  "https://www.jud.ct.gov/attorneyfirminquiry/attorneyfirminquiry.aspx"
        digest = CtCourtJudCtGov.find_by(md5_hash: create_md5_hash(hash), deleted: false)
        if digest.nil?
          hash.merge!({run_id: @run_id, touched_run_id: @run_id, data_source_url: source_url,  md5_hash: create_md5_hash(hash)})
          main_arr << hash
        else
          digest.update(touched_run_id: @run_id)
          digest
        end
      end

      unless main_arr.nil? || main_arr.empty?
        CtCourtJudCtGov.insert_all(main_arr)
      end
    end
  end

  def update_delete_status
    CtCourtJudCtGov.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end

  def finish
    @run_object.finish
  end
end
