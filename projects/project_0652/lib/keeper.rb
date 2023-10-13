# frozen_string_literal: true

require_relative '../models/fl_ccsjcpc_case_activity'
require_relative '../models/fl_ccsjcpc_case_info'
require_relative '../models/fl_ccsjcpc_case_party'
require_relative '../models/fl_ccsjcpc_case_pdfs_on_aws'
require_relative '../models/fl_ccsjcpc_case_relations_activity_pdf'
require_relative '../models/fl_ccsjcpc_case_run'
require_relative '../models/fl_ccsjcpc_case_processed'

class Keeper
  
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(FlCcsjcpcCaseRun)
    @run_id = @run_object.run_id
    # @run_id = 1
  end

  def store(data)
    # insert case info
    unless data[:case].nil?
      insert_model(FlCcsjcpcCaseInfo, data[:case])
      # add record in meta table
      FlCcsjcpcCaseProcessed.insert(data[:case].slice(:case_id))
    end
    # insert parties info
    unless data[:parties].nil?
      data[:parties].each do |party|
        insert_model(FlCcsjcpcCaseParty, party)
      end
    end
    # insert activities info
    unless data[:activities].nil?
      data[:activities].each do |activity|
        insert_model(FlCcsjcpcCaseActivity, activity.except(:pdf_on_aws,:pdf_on_aws_relation))
        # insert pdf details
        unless activity[:pdf_on_aws].nil?
            insert_model(FlCcsjcpcCasePdfsOnAws, activity[:pdf_on_aws])
        end
        # insert relations
        unless activity[:pdf_on_aws_relation].nil?
          insert_model(FlCcsjcpcCaseRelationsActivityPdf, activity[:pdf_on_aws_relation])
        end
      end
    end

  end

  def finish(update_run_id)
    mark_as_deleted
    @run_object.finish if update_run_id ==  true
  end

  
  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end


  def insert_model(model, hash)
    existing = model.find_by(md5_hash: hash[:md5_hash])
    # replace empty values with nil
    hash.each { |k, v| hash[k] = nil if v.kind_of?(String) && v.empty? }
    unless existing.nil?
      existing.update(touched_run_id: hash[:run_id],deleted: 0) 
    end
    model.insert(hash) if existing.nil?
  end

  def mark_as_deleted
    [FlCcsjcpcCaseInfo,FlCcsjcpcCaseParty,FlCcsjcpcCaseActivity,FlCcsjcpcCasePdfsOnAws].each do |model|
      model.where(deleted: 0, case_id: FlCcsjcpcCaseProcessed.select(:case_id)).where.not(touched_run_id: @run_id).update_all(deleted:1)
    end
    FlCcsjcpcCaseRelationsActivityPdf.where(
      deleted: 0, 
      case_activities_md5: FlCcsjcpcCaseActivity.where(deleted: 0, case_id: FlCcsjcpcCaseProcessed.select(:case_id)).select(:md5_hash))
      .where.not(touched_run_id: @run_id).update_all(deleted:1)
    # truncate existing meta processing
    FlCcsjcpcCaseProcessed.connection.truncate(FlCcsjcpcCaseProcessed.table_name)
  end

end
