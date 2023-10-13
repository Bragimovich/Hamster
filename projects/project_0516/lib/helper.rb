# frozen_string_literal: true

class Helper < Hamster::Parser
  def initialize
    super
  end

# ======================= MERGE block =======================
  def merge_activities_with_links(main_hash, links_arr)
    main_hash[:activities].each_with_index do |el, idx|
      links_arr.size.times do
        main_hash[:activities][idx].merge!(links_arr.shift.slice(:file)) if compare?(el, links_arr.first)
        break if main_hash[:activities][idx][:file]
        links_arr.rotate!
      end
    end
    # append the rest of links (if present)
    links_arr.each do |el|
      main_hash[:activities] << el
    end
    main_hash
  end

  # --------------- auxiliary methods ---------------
  def compare?(activity, document)
    activity[:activity_date].eql?(document[:activity_date]) && similar?(activity[:activity_type], document[:activity_type])
  end

  def similar?(activity_type, document_type)
    doc_name = document_type.split.first
    doc_abbr = document_type.split('(').last.split(')').first
    activity_type.upcase.include?(doc_name.upcase) || activity_type.upcase.include?(doc_abbr.upcase)
  end
# ===================== MERGE block ends =====================

# =================== ADD ADDITIONAL block ===================
  def add_additional(the_case)
    existed_pdfs_links = Keeper.new.get_pdf_md5_hash(the_case[:info][:case_id])
    pdfs_on_aws             = []
    relations_activity_pdf  = []
    relations_info_pdf      = []
    key_start = "us_courts_#{the_case[:info][:court_id]}_#{the_case[:info][:case_id]}_"

    # ---------------------- case_info section ---------------------
    md5_info = MD5Hash.new(table: :info)
    the_case[:info][:data_source_url] = the_case[:links][:data_source_url]
    the_case[:info][:md5_hash] = md5_info.generate(the_case[:info])
    # -------------------- case_info section ends -------------------

    # ---------------------- case_party section ---------------------
    md5_party = MD5Hash.new(table: :party)
    the_case[:parties].each_index do |i|
      the_case[:parties][i][:court_id] = the_case[:info][:court_id]
      the_case[:parties][i][:case_id] = the_case[:info][:case_id]
      the_case[:parties][i][:data_source_url] = the_case[:info][:data_source_url]
      the_case[:parties][i][:md5_hash] = md5_party.generate(the_case[:parties][i])
    end
    # -------------------- case_party section ends -------------------

    # -------------------- additional_info section -------------------
    md5_additional_info = MD5Hash.new(:columns => %w(court_id case_id lower_court_name lower_case_id lower_judge_name lower_judgement_date lower_link disposition data_source_url))
    the_case[:additional_info].each_index do |i|
      the_case[:additional_info][i][:court_id] = the_case[:info][:court_id]
      the_case[:additional_info][i][:case_id] = the_case[:info][:case_id]
      the_case[:additional_info][i][:data_source_url] = the_case[:info][:data_source_url]
      the_case[:additional_info][i][:md5_hash] = md5_additional_info.generate(the_case[:additional_info][i])
    end
    # ----------------- additional_info section ends -----------------

    # ----------------- case_activities + pdfs_on_aws ----------------
    # ----------------- relations_activity_pdf section ---------------
    md5_pdf_on_aws = MD5Hash.new(table: :pdfs_on_aws)
    md5_activities = MD5Hash.new(:columns => %w(court_id case_id activity_date activity_type activity_desc file data_source_url))
    the_case[:activities].each_index do |i|
      the_case[:activities][i][:court_id] = the_case[:info][:court_id]
      the_case[:activities][i][:case_id] = the_case[:info][:case_id]
      the_case[:activities][i][:data_source_url] = the_case[:info][:data_source_url]

      md5_hash_activity = md5_activities.generate(the_case[:activities][i])
      the_case[:activities][i][:md5_hash] = md5_hash_activity

      url_file = the_case[:activities][i][:file]

      if !url_file.nil?
        next if md5_hash_activity.in?(existed_pdfs_links)
        begin
          url_pdf_on_aws = Scraper.new.save_to_aws(url_file, key_start)
        rescue StandardError => e
          [STARS,  e].each {|line| logger.error(line)}
          Hamster.report to: OLEKSII_KUTS, message: "516_nc_saac_case_*. can't store file #{url_file} to aws... Skipping"
          next # just skip this file
        end
        the_case[:activities][i][:file] = url_pdf_on_aws

        pdfs_on_aws.push({
                           court_id:        the_case[:info][:court_id],
                           case_id:         the_case[:info][:case_id],
                           source_type:     'activities',
                           aws_link:        url_pdf_on_aws,
                           source_link:     url_file,
                           data_source_url: the_case[:activities][i][:data_source_url]
                         })
        pdfs_on_aws[-1][:md5_hash] = md5_pdf_on_aws.generate(pdfs_on_aws[-1])

        relations_activity_pdf.push({
                                      court_id:             the_case[:info][:court_id],
                                      case_id:              the_case[:info][:case_id],
                                      case_pdf_on_aws_md5:  pdfs_on_aws[-1][:md5_hash],
                                      case_activities_md5:  the_case[:activities][i][:md5_hash]
                                    })
      end
    end
    # ----------------- case_activities + pdfs_on_aws ----------------
    # -------------- relations_activity_pdf section ends -------------

    # ------------------ relations_info_pdf section ------------------
    pdfs_on_aws.push({
                       court_id:        the_case[:info][:court_id],
                       case_id:         the_case[:info][:case_id],
                       source_type:     'info',
                       aws_link:        the_case[:links][:aws_link],
                       source_link:     the_case[:links][:source_link],
                       data_source_url: the_case[:links][:data_source_url]
                     })
    pdfs_on_aws[-1][:md5_hash] = md5_pdf_on_aws.generate(pdfs_on_aws[-1])

    relations_info_pdf.push({
                              court_id:             the_case[:info][:court_id],
                              case_id:              the_case[:info][:case_id],
                              case_pdf_on_aws_md5:  pdfs_on_aws[-1][:md5_hash],
                              case_info_md5:        the_case[:info][:md5_hash]
                            })
    # --------------- relations_info_pdf section ends ----------------

    the_case[:pdfs_on_aws] = pdfs_on_aws
    the_case[:relations_activity_pdf] = relations_activity_pdf
    the_case[:relations_info_pdf] = relations_info_pdf
    the_case
  end
# ================= ADD ADDITIONAL block ends ================
end
