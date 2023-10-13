require_relative '../models/ri_sc_case_activities'
require_relative '../models/ri_sc_case_additional_info'
require_relative '../models/ri_sc_case_info'
require_relative '../models/ri_sc_case_party'
require_relative '../models/ri_sc_case_pdfs_on_aws'
require_relative '../models/ri_sc_case_relations_activity_pdf'
require_relative '../models/ri_sc_case_run'
require_relative 'scraper'

class Keeper
  def initialize
    super
    @run_id = run.run_id
  end

  attr_reader :run_id

  def status=(new_status)
    run.status = new_status
  end

  def finish
    run.finish
  end

  def store(i, pdf, file_name)
    source_type = 'activity'
    [[i], pdf[0], pdf[1]].map! do |part|
      part.map! do |ha_info|
        ha_info.each {|key, val| val.to_s.empty? ? ha_info[key] = nil : val}
      end
    end
    pdf[0].each do |info|
      ri_sc_case_activities            = {run_id: run_id,
                                          touched_run_id: run_id,
                                          activity_date: i[:activity_date],
                                          file: i[:file],
                                          data_source_url: i[:link],
                                          court_id: info[:court_id],
                                          case_id: info[:case_id],
                                          activity_type: info[:activity_type]
      }
      ri_sc_case_activities[:md5_hash] = MD5Hash.new(columns: [:activity_date, :file,
                                                               :data_source_url, :court_id,
                                                               :case_id, :activity_type
      ]).generate(ri_sc_case_activities)
      ri_sc_case_activities_db         = RiScCaseActivities.find_by(case_id: ri_sc_case_activities[:case_id],
                                                                    data_source_url: ri_sc_case_activities[:data_source_url],
                                                                    deleted: 0
      )
      if ri_sc_case_activities_db.nil?
        !ri_sc_case_activities[:case_id].nil? ? RiScCaseActivities.store(ri_sc_case_activities) : ri_sc_case_activities
      else
        if ri_sc_case_activities_db[:md5_hash] == ri_sc_case_activities[:md5_hash]
            ri_sc_case_activities_db.update(touched_run_id: run_id)
        else
          ri_sc_case_activities_db.update(deleted: 1)
          RiScCaseActivities.store(ri_sc_case_activities)
        end
      end
      ri_sc_case_info            = {run_id: run_id,
                                    touched_run_id: run_id,
                                    case_name: info[:case_name],
                                    case_description: i[:case_description],
                                    court_id: info[:court_id],
                                    case_id: info[:case_id],
                                    status_as_of_date: info[:status_as_of_date],
                                    judge_name: info[:judge_name],
                                    lower_case_id: info[:lower_case_id],
                                    data_source_url: i[:link]
      }
      ri_sc_case_info[:md5_hash] = MD5Hash.new(columns: [:case_name,
                                                         :case_description,
                                                         :court_id,
                                                         :case_id,
                                                         :status_as_of_date,
                                                         :judge_name,
                                                         :lower_case_id,
                                                         :data_source_url
      ]).generate(ri_sc_case_info)
      ri_sc_case_info_db         = RiScCaseInfo.find_by(case_id: ri_sc_case_info[:case_id],
                                                        data_source_url: ri_sc_case_info[:data_source_url],
                                                        deleted: 0
      )
      if ri_sc_case_info_db.nil?
        if ri_sc_case_info[:case_id].nil? && ri_sc_case_info[:case_name].nil?
          ri_sc_case_info
        else
          RiScCaseInfo.store(ri_sc_case_info)
        end
      else
        if ri_sc_case_info_db[:md5_hash] == ri_sc_case_info[:md5_hash]
          ri_sc_case_info_db.update(touched_run_id: run_id)
        else
          ri_sc_case_info_db.update(deleted: 1)
          RiScCaseInfo.store(ri_sc_case_info)
        end
      end
    ri_sc_case_additional_info            = {run_id: run_id,
                                             touched_run_id: run_id,
                                             court_id: info[:court_id],
                                             case_id: info[:case_id],
                                             lower_court_name: info[:lower_court_name],
                                             lower_case_id: info[:lower_case_id],
                                             data_source_url: i[:link]
    }
    ri_sc_case_additional_info[:md5_hash] = MD5Hash.new(columns: [:court_id,
                                                                  :case_id,
                                                                  :lower_court_name,
                                                                  :lower_case_id,
                                                                  :data_source_url

    ]).generate(ri_sc_case_additional_info)
    ri_sc_case_additional_info_db         = RiScCaseAdditionalInfo.find_by(deleted: 0,
                                                                           case_id: ri_sc_case_additional_info[:case_id],
                                                                           data_source_url: ri_sc_case_additional_info[:data_source_url]
    )
    if ri_sc_case_additional_info_db.nil?
      if ri_sc_case_additional_info[:case_id].nil? && ri_sc_case_additional_info[:lower_court_name].nil? && ri_sc_case_additional_info[:lower_case_id].nil?
        ri_sc_case_additional_info
      else
        RiScCaseAdditionalInfo.store(ri_sc_case_additional_info)
      end
    else
      if ri_sc_case_additional_info_db[:md5_hash] == ri_sc_case_additional_info[:md5_hash]
        ri_sc_case_additional_info_db.update(touched_run_id: run_id)
      else
        ri_sc_case_additional_info_db.update(deleted: 1)
        RiScCaseAdditionalInfo.store(ri_sc_case_additional_info)
      end
    end
    scraper                           = Scraper.new
    file_aws                          = info[:court_id].to_s + '/' + info[:case_id].to_s + '/' + file_name
    ri_sc_case_pdfs_on_aws            = {run_id: run_id,
                                         touched_run_id: run_id,
                                         court_id: info[:court_id],
                                         case_id: info[:case_id],
                                         source_type: source_type,
                                         aws_link: nil,
                                         source_link: i[:link],
                                         aws_html_link: nil
    }
    ri_sc_case_pdfs_on_aws[:md5_hash] = MD5Hash.new(columns: [:court_id,
                                                              :case_id,
                                                              :source_type,
                                                              :source_link,
                                                              :aws_html_link
    ]).generate(ri_sc_case_pdfs_on_aws)
    ri_sc_case_pdfs_on_aws_db         = RiScCasePdfsOnAws.find_by(deleted: 0,
                                                                  case_id: ri_sc_case_pdfs_on_aws[:case_id],
                                                                  source_link: ri_sc_case_pdfs_on_aws[:source_link]
    )
    if ri_sc_case_pdfs_on_aws_db.nil?
      aws_link = scraper.save_aws(i[:link], file_aws) #<= AWS!!!
      ri_sc_case_pdfs_on_aws[:aws_link] = aws_link
      RiScCasePdfsOnAws.store(ri_sc_case_pdfs_on_aws)
    else
      if ri_sc_case_pdfs_on_aws_db[:md5_hash] == ri_sc_case_pdfs_on_aws[:md5_hash]
        ri_sc_case_pdfs_on_aws_db.update(touched_run_id: run_id)
      else
        ri_sc_case_pdfs_on_aws_db.update(deleted: 1)
        aws_link = scraper.save_aws(i[:link], file_aws) #<= AWS!!!
        ri_sc_case_pdfs_on_aws[:aws_link] = aws_link
        RiScCasePdfsOnAws.store(ri_sc_case_pdfs_on_aws)
      end
    end
    ri_sc_case_relations_activity_pdf_db = RiScCaseRelationsActivityPdf.find_by(case_pdf_on_aws_md5: ri_sc_case_pdfs_on_aws[:md5_hash],
                                                                                deleted: 0
    )
    ri_sc_case_relations_activity_pdf    = {run_id: run_id,
                                            touched_run_id: run_id,
                                            case_activities_md5: ri_sc_case_activities[:md5_hash],
                                            case_pdf_on_aws_md5: ri_sc_case_pdfs_on_aws[:md5_hash]
    }
    if ri_sc_case_relations_activity_pdf_db.nil?
      RiScCaseRelationsActivityPdf.store(ri_sc_case_relations_activity_pdf)
    else
      if ri_sc_case_relations_activity_pdf_db[:case_activities_md5] == ri_sc_case_activities[:md5_hash]
        ri_sc_case_relations_activity_pdf_db.update(touched_run_id: run_id)
      else
        ri_sc_case_relations_activity_pdf_db.update(deleted: 1)
        RiScCaseRelationsActivityPdf.store(ri_sc_case_relations_activity_pdf)
      end
    end
      pdf[1].each do |info_party|
        ri_sc_case_party            = {run_id: run_id,
                                       touched_run_id: run_id,
                                       court_id: info_party[:court_id],
                                       is_lawyer: info_party[:is_lawyer],
                                       party_name: info_party[:party_name],
                                       party_type: info_party[:party_type],
                                       data_source_url: i[:link]
        }
        ri_sc_case_party[:md5_hash] = MD5Hash.new(columns: [:court_id,
                                                            :is_lawyer,
                                                            :party_name,
                                                            :party_type,
                                                            :data_source_url
        ]).generate(ri_sc_case_party)
        ri_sc_case_party_db = RiScCaseParty.find_by(deleted: 0,
                                                    party_name: ri_sc_case_party[:party_name],
                                                    party_type: ri_sc_case_party[:party_type],
                                                    md5_hash: ri_sc_case_party[:md5_hash]
        )
        if ri_sc_case_party_db.nil?
          if ri_sc_case_party[:is_lawyer].nil? && ri_sc_case_party[:party_name].nil? && ri_sc_case_party[:party_type].nil?
            next
          else
            RiScCaseParty.store(ri_sc_case_party)
          end
        else
          if ri_sc_case_party_db[:md5_hash] == ri_sc_case_party[:md5_hash]
            ri_sc_case_party_db.update(touched_run_id: run_id)
          else
            ri_sc_case_party_db.update(deleted: 1)
            RiScCaseParty.store(ri_sc_case_party)
          end
        end
      end
    end
  end

  def delete_empty_rows
    RiScCaseActivities.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    RiScCaseAdditionalInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    RiScCaseInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    RiScCaseParty.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    RiScCasePdfsOnAws.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    RiScCaseRelationsActivityPdf.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  private
  def run
    RunId.new(RiScCaseRun)
  end

  rescue => e
    Hamster.logger.error(e.full_message)
end
