# frozen_string_literal: true

class Helper < Hamster::Parser
  def initialize
    super
  end

  def add_additional(the_case)
    
    pdfs_on_aws             = []
    relations_activity_pdf  = []

    md5_pdf_on_aws = MD5Hash.new(table: :pdfs_on_aws)
    
    the_case[:activities].each_index do |i|

      md5_hash_activity = the_case[:activities][i][:md5_hash]
      url_file = the_case[:activities][i][:file]
      
      unless url_file.nil?
       
        params = {
          url: url_file,
          court_id: the_case[:info][:court_id],
          case_id: the_case[:info][:case_id],
          extension: '.pdf',
        }
        url_pdf_on_aws = Scraper.new.save_to_aws(url: url_file, court_id: the_case[:info][:court_id], case_id: the_case[:info][:case_id], extension: '.pdf')
        
        the_case[:activities][i][:file] = url_pdf_on_aws
        md5_activities = MD5Hash.new(:columns => %w(court_id case_id activity_date activity_type activity_desc file data_source_url))
        the_case[:activities][i][:md5_hash] = md5_activities.generate(the_case[:activities][i])
        
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
        data_string = relations_activity_pdf[-1].values.inject('') { |str, val| str += val.to_s }
        relations_activity_pdf[-1][:md5_hash] = Digest::MD5.hexdigest(data_string)
      end
    end
    the_case[:pdfs_on_aws] = pdfs_on_aws
    the_case[:relations_activity_pdf] = relations_activity_pdf
    the_case
  end

end
