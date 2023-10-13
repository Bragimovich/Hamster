# frozen_string_literal: true
require_relative '../models/eeoc_briefs'
require_relative '../models/eeoc_parties'
require_relative '../models/eeoc_comission'
require_relative '../models/eeoc_runs'

class Keeper

  def initialize
    @run_object = RunId.new(EeocRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def finish
    @run_object.finish
  end

  def mark_download_status(id)
    EeocRuns.where(id: run_id).update(download_status: "True")
  end

  def download_status(id)
    EeocRuns.where(id: run_id).pluck(:download_status)
  end

  def get_parent_data
    EcocBriefs.where.not(read_brief_url: nil).pluck(:read_brief_url, :id)
  end

  def get_download_files
    EcocBriefs.where.not(read_brief_url: nil).pluck(:read_brief_url).reject{|e| !e.end_with? ".pdf"}
  end

  def get_inserted_links
    EcocBriefs.pluck(:case_url)
  end

  def make_insertions(data_array, model)
    data_array.count < 5000 ? model.constantize.insert_all(data_array) : data_array.each_slice(5000){|data| model.constantize.insert_all(data)} unless (data_array.nil?) || (data_array.empty?)
  end

  def mark_dirty
    records = EcocBriefs.joins("left join eeoc_parties p ON eeoc_briefs.id = p.case_id left join eeoc_comission c on eeoc_briefs.id = c.case_id where (p.id is null or c.id is null) and eeoc_briefs.dirty = 0").uniq
    records.each do |record|
      record.update(:dirty => 1)
    end
  end
end
