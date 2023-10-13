# frozen_string_literal: true

require_relative '../models/oh_10th_ac_case_info'
require_relative '../models/oh_10th_ac_case_additional_info'
require_relative '../models/oh_10th_ac_case_activities'
require_relative '../models/oh_10th_ac_case_party'
require_relative '../models/oh_10th_ac_case_pdfs_on_aws'
require_relative '../models/oh_10th_ac_case_relations_activity_pdf'
require_relative '../models/oh_10th_ac_case_relations_info_pdf'
require_relative '../models/oh_fccc_case_info'
require_relative '../models/oh_fccc_case_activities'
require_relative '../models/oh_fccc_case_party'
require_relative '../models/oh_fccc_case_judgment'
require_relative '../models/oh_fccc_case_pdfs_on_aws'
require_relative '../models/oh_fccc_case_relations_activity_pdf'
require_relative '../models/oh_fccc_case_relations_info_pdf'
require_relative '../models/runs'

class  Keeper < Hamster::Harvester
  attr_writer :data_hash, :type

  def initialize(args)
    if args[:download] || args[:auto] || args[:update]
      @run_object = RunId.new(Runs)
      @run_id = @run_object.run_id
    else
      @run_id = Runs.last
    end
  end

  def store_info
    digest_update(Oh10thAcCaseInfo, @data_hash) if @type == "AP"
    digest_update(OhFcccCaseInfo, @data_hash) if @type != "AP"
  end

  def store_additional_info
    digest_update(Oh10thAcCaseAdditionalInfo, @data_hash) if @type == "AP"
  end

  def store_activities
    @data_hash[:files_table].each do |row|
      activities_hash = {
        case_id: @data_hash[:case_id],
        activity_date: [row][0][:date],
        activity_decs: [row][0][:desc],
        activity_type: [row][0][:name],
        file: [row][0][:link]
       }
      @activity = digest_update(Oh10thAcCaseActivities, activities_hash) if @type == "AP"
      @activity = digest_update(OhFcccCaseActivities, activities_hash) if @type != "AP"
      row.merge!(complaint_id: @activity.id)
    end
  end

  def store_judgment
    unless @data_hash[:judgment].nil?
      judgment_hash = {
        case_id: @data_hash[:case_id],
        complaint_id: @activity.id,
        judgment_amount: @data_hash[:judgment].nil? ? nil : @data_hash[:judgment][:judgment],
        judgment_date: @data_hash[:judgment].nil? ? nil : @data_hash[:judgment][:date]
        }
        digest_update(OhFcccCaseJudgment, judgment_hash) if @type != "AP"
    end
  end

  def store_party
    @data_hash[:appellants][:attorney].size.times do |i|
      hash = appell_hash(@data_hash[:appellants], i)      
      digest_update(Oh10thAcCaseParty, hash) if @type == "AP"
      digest_update(OhFcccCaseParty, hash) if @type != "AP"
    end rescue nil

    @data_hash[:appellee][:attorney].size.times do |i|
      hash = appell_hash(@data_hash[:appellee], i)  
      digest_update(Oh10thAcCaseParty, hash) if @type == "AP"
      digest_update(OhFcccCaseParty, hash) if @type != "AP"
    end rescue nil

    @data_hash[:appellants][:name].size.times do |i|
      hash = appell_name_hash(@data_hash[:appellants], i)      
      digest_update(Oh10thAcCaseParty, hash) if @type == "AP"
      digest_update(OhFcccCaseParty, hash) if @type != "AP"
    end rescue nil

    @data_hash[:appellee][:name].size.times do |i|
      hash = appell_name_hash(@data_hash[:appellee], i)  
      digest_update(Oh10thAcCaseParty, hash) if @type == "AP"
      digest_update(OhFcccCaseParty, hash) if @type != "AP"
    end rescue nil
  end

  def store_aws
    @data_hash[:files_table].each do |hash|
      aws_hash = {
          case_id:  @data_hash[:case_id],
          complaint_id: hash[:complaint_id],
          source_type: "activity",
          source_link: hash[:link]
          }
      digest_update(Oh10thAcCasePdfsOnAws, aws_hash) if @type == "AP"
      digest_update(OhFcccCasePdfsOnAws, aws_hash) if @type != "AP"
    end
  end

  def store_description(desc_arr, object_info)
    desc_arr.each do |row|
      object_info.where(case_id: row[:case_id]).where(case_name: nil).update(case_name: row[:name], case_description: row[:desc])
    end
  end

  def update_aws_link(aws_link, info, object)
    object.where(case_id: info[0], source_link: info[1]).update(aws_link: aws_link)
  end

  def store_relations_activity
    relations_activity_update(Oh10thAcCasePdfsOnAws , Oh10thAcCaseActivities, Oh10thAcCaseRelationsActivityPdf )
    relations_activity_update(OhFcccCasePdfsOnAws, OhFcccCaseActivities, OhFcccCaseRelationsActivityPdf)
  end

  def store_relations_info
    relations_info_update(Oh10thAcCaseRelationsInfoPdf, Oh10thAcCaseInfo, Oh10thAcCasePdfsOnAws)
    relations_info_update(OhFcccCaseRelationsInfoPdf, OhFcccCaseInfo, OhFcccCasePdfsOnAws)
  end

  def update_delete_status
    Oh10thAcCaseInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    Oh10thAcCaseAdditionalInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    Oh10thAcCaseActivities.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    Oh10thAcCaseParty.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    Oh10thAcCasePdfsOnAws.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    OhFcccCaseInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    OhFcccCaseActivities.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    OhFcccCaseParty.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    OhFcccCaseJudgment.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    OhFcccCasePdfsOnAws.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
  end
  
  def finish
    @run_object.finish
  end

  private
  
  def appell_hash(key, i)
    {
      case_id: @data_hash[:case_id],
      party_name: key[:attorney][i],
      party_type: key[:party_type],
      party_address: key[:attorney_info].nil? ? nil : key[:attorney_info][i][:address] ,
      party_city: key[:attorney_info].nil? ? nil : key[:attorney_info][i][:city],
      party_state: key[:attorney_info].nil? ? nil : key[:attorney_info][i][:state],
      party_zip: key[:attorney_info].nil? ? nil : key[:attorney_info][i][:zip],
      law_firm: key[:attorney_firm].nil? ? nil : key[:attorney_firm][i],
      lawyer_additional_data: key[:attorney_raw_info].nil? ? nil : key[:attorney_raw_info][i],
      is_lawyer: 1
    }
  end

  def appell_name_hash(key, i)
    {
      case_id: @data_hash[:case_id],
      party_name: key[:name][i],
      party_type: key[:party_type],
      party_address: key[:name_info].nil? ? nil : key[:name_info][i][:address] ,
      party_city: key[:name_info].nil? ? nil : key[:name_info][i][:city],
      party_state: key[:name_info].nil? ? nil : key[:name_info][i][:state],
      party_zip: key[:name_info].nil? ? nil : key[:name_info][i][:zip],
      lawyer_additional_data: key[:name_raw_info].nil? ? nil : key[:name_raw_info][i],
      is_lawyer: 0
    }
  end

  def find_md5_hash(object, row)
    hash = object.flail { |key| [key, row[key]] }
    object.find_by(md5_hash: create_md5_hash(hash))
  end

  def relations_digest_update(object, h, link)
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(case_pdf_on_aws_md5: link[:md5_hash])
    if digest.nil?
      object.store(hash)
    end
  end

  def relations_info_update(object, info_object, aws_object)
    case_id_pdf = aws_object.select(:case_id, :md5_hash)
    case_id_pdf.each do |link| 
      info_md5 = info_object.where(case_id: (link[:case_id])).pluck(:md5_hash)
      info_md5_hash = {
        case_info_md5: info_md5.join,
        case_pdf_on_aws_md5: link[:md5_hash]
      }
      relations_digest_update(object, info_md5_hash, link )
    end
  end

  def relations_activity_update(object, activity_object, aws_object)
    source_link = object.select(:source_link, :md5_hash)
    source_link.each do |link| 
      file = activity_object.where(file: link[:source_link]).pluck(:md5_hash)
      activity_md5_hash = {
        case_activities_md5: file.join,
        case_pdf_on_aws_md5: link[:md5_hash]
      }
      relations_digest_update(aws_object, activity_md5_hash, link)
    end
  end

  def digest_update(object, h)
    court_id = 61
    court_id = 38 if @type == "AP"
    court_id = 62 if @type == "DR"

    source_url = "https://fcdcfcjs.co.franklin.oh.us/CaseInformationOnline/"
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash), deleted: false)
  
    if digest.nil?
      hash.merge!({court_id: court_id, run_id: @run_id, touched_run_id: @run_id, data_source_url: source_url,  md5_hash: create_md5_hash(hash)})
      object.store(hash)
    else
      digest.update(touched_run_id: @run_id)
      digest
    end
  end

  def create_md5_hash(hash)
    str = ""
    hash.each do |field|
      unless field.include?(:file) || field.include?(:source_link)
        str += field.to_s
      end
    end
    digest = Digest::MD5.new.hexdigest(str)
  end
end
