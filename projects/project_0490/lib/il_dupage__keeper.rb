# frozen_string_literal: true

require_relative '../lib/il_dupage__run'
require_relative '../models/il_dupage__runs'

class IlDuPageKeeper < Hamster::Harvester

  CHUNK = 1000

  def initialize
    super
    @s3 = AwsS3.new(:hamster, :hamster)
    @key_start = 'crime_perps_mugshots/il/dupage/'
    @runner = RunManager.new(IlDuPageRun)
  end

  def clear_store_folder
    trash_folder = @runner.run_id.to_s.rjust(4, "0")
    peon.give_list.each do |file|
      peon.move(file: file, to: trash_folder)
    end
  end

  def start_download
    @runner.restart if @runner.status != 'processing'
    @runner.status = 'download started'
  end

  def finish_download
    @runner.status = 'download finished'
  end

  def start_store
    if @runner.status == 'download finished'
      @runner.status = 'store started'
    else
      raise
    end
  end

  def finish
    @runner.finish
  end

  def save_to_aws(url_file, file_content)
    file_name = url_file.split('/').last(3).join("_")
    file_name += '.jpg'
    key = @key_start + file_name
    @s3.put_file(file_content, key, metadata = { url: url_file })
  end

  def arrestee_mugshot(inmate_id)
    IlDuPageMugshot.find_by(deleted: 0, arrestee_id: inmate_id)
  end

  def store_all(records, model)
    model.insert_all(records) unless records.empty?
  end

  def store(record, model)
    record[:run_id] = @runner.run_id
    record[:touched_run_id] = @runner.run_id
    model.insert record
  end

  def find_id_by_md5(model, value)
    model.find_by(md5_hash: value).id
  end

  def last_id(model)
    model.last.id
  end

  def run_id
    IlDuPageRun.last.id
  end

  def list_saved_md5(model)
    model.where(deleted: 0).pluck(:md5_hash).to_set
  end

  def save_file(doc, name, folder = nil)
    peon.put(content: doc, file: name, subfolder: folder)
  end

  def give_file(name, folder = nil)
    peon.give(file: name, subfolder: folder)
  end

  def update_touched_run_id(model, md5_hash)
      model.where(deleted: 0, md5_hash: md5_hash).update(touched_run_id: @runner.run_id)
  end

  def update_all_touched_run_id(model, unchanged_md5)
    unchanged_md5.each_slice(CHUNK) do |md5_chunk|
      model.where(md5_hash: md5_chunk).update_all(touched_run_id: @runner.run_id)
    end
  end

  def update_deleted_status(model)
    model.where(deleted: 0).where.not(touched_run_id: @runner.run_id).update_all(deleted: 1)
  end

end
