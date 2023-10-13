# frozen_string_literal: true

require_relative '../models/FSCALNames'
require_relative '../models/FSCALPdfs'

class Parser <  Hamster::Scraper

  def initialize
    super  
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @all_pdfs = FSCALPdfs.where("pdf_link_on_aws like 'https://court-cases-activities.s3.amazonaws.com%'").pluck(:id , :pdf_link_on_aws)
    @already_processed = FSCALNames.pluck(:data_source_url)
  end

  def parser
    @all_pdfs.each do |data|
      next if @already_processed.include? data[1]
      id = data[0]
      p file_name = data[1].split("/").last.gsub("florida_supreme_court_" , "").strip
      #file_name = "2021-1774_letter_75893_ack03_SC21-1774.pdf" 
      next if  file_name == "2017-1620_letter_55026_SC17-1620.pdf"		
      pdf_file_path = "#{storehouse}store/#{file_name}"
      reader = PDF::Reader.new(open(pdf_file_path))
      document = reader.pages.first.text.scan(/^.+/)
      tracker = document.select{|e| e.include? "cc:"}
      ind = document.index tracker.first rescue nil
      if ind.nil?
        document = reader.pages[1].text.scan(/^.+/)
        tracker = document.select{|e| e.include? "cc:"}
        ind = document.index tracker.first rescue nil
        store(document , ind + 1 , -1 , data[1] , id)
      elsif (ind + 1 == document.count) and !ind.nil?
        document = reader.pages[1].text.scan(/^.+/)
        store(document , 2 , -1 , data[1] , id)
      else
        store(document , ind + 1 , -1 , data[1] , id)
        if reader.pages.count > 1
         document = reader.pages[1].text.scan(/^.+/)
         store(document , 2 , -1 , data[1] , id) 	  
        end
      end
    end
  end

  def store(document , start_ind , end_ind , url , id)
    data_array = []
    document[start_ind..end_ind].each do |lawyer_name|
      next if lawyer_name.include? "document"
      prepare_name(lawyer_name).each do |lwy_name|
        next if lwy_name != lwy_name.upcase
        data_hash = {
          letter_id: id,
          lawyer_name: lwy_name.strip, 
          data_source_url: url
        }
        data_array.push(data_hash)
      end
    end
  
    FSCALNames.insert_all(data_array) if !data_array.empty?
  end

  def prepare_name(lawyer_name)
    array = []
    count = lawyer_name.strip.scan(/(\s+)/).reject{|e| e.first == " " or e.first == "  " or e.first == "   "}.count
    if count != 0
      chunk = lawyer_name.strip.scan(/(\s+)/).reject{|e| e.first == " " or e.first == "  " or e.first == "   "}.first.first
      return lawyer_name.strip.split(chunk)  
    else
      array << lawyer_name
      return array
    end
  end
end

