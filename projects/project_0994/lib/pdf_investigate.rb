# frozen_string_literal: true
#
#
require_relative '../models/us_cases2'
require 'rtesseract'
require 'pdftoimage'



# def get_pdf
#   CaseTypesDivided.where(general_category:'civil').values
#   "SELECT case_id from us_case_info WHERE case_type in (select `values` from us_case_types where general_category='civil') limit 7000"
#
# end
#
COURTS_ID = [1, 2, 12, 35, 38, 42, 48, 49]

def pdf_from_aws(court_id=nil, stream=1, streams=1)
  limit = 10

  if court_id == nil or !court_id.to_i.in?(COURTS_ID)
    courts = COURTS_ID
  else
    courts = [court_id]
  end

  courts.each do |court|
    p court

    counts = UsCaseActivitiesPDFCourts.where(court_id:court).count

    pages_for_stream = (counts/limit)/streams

    page_start = (stream-1)*pages_for_stream
    page_last = stream*pages_for_stream

    (page_start..page_last).to_a.each do |page|
      p page

      activitites_to_db = []

      activitities = UsCaseActivitiesPDFCourts.where(court_id:court).limit(limit).offset(limit*page)

      links = activitities.map { |row| 'https://court-cases-activities.s3.amazonaws.com/'+row[:file].gsub(' ','%20') }

      existed_links = get_existing_pdf(links)

      activitities.each do |activity|
        file = 'https://court-cases-activities.s3.amazonaws.com/'+activity[:file].gsub(' ','%20')
        next if file.in?(existed_links)
        pdf_file = Faraday.get(file).body
        path_file = "pdf_files/#{activity[:file].gsub(' ','%20')}.pdf"
        File.open(path_file, 'wb') { |fp| fp.write(pdf_file) }
        p path_file
        ocr = 0
        begin
          reader = PDF::Reader.new(path_file)

          text_pdf = ''
          reader.pages.each do |page|
            text_pdf += page.text
          end

          keywords_hash = how_many_words(text_pdf)

          if keywords_hash.empty?
            text_ocr = ''
            images = PDFToImage.open(path_file)
            images.each do |img|
              filename = "#{path_file}#{img.page}.jpg"
              img.save(filename)
              image = RTesseract.new(filename)
              text_ocr += image.to_s
              File.delete(filename) if File.exist?(path_file)
            end
            keywords_hash = how_many_words(text_ocr)
            ocr = 1
          end

          keywords_hash_top_5 = keywords_hash.sort_by { |keyword, count| count }.last(5).reverse
          activitites_to_db.push({
                                   court_id: activity.court_id,
                                    case_id:activity.case_id,
                                   activity_id: activity.activity_id,
                                   link_to_pdf: file,
                                   top5keywords: keywords_hash_top_5.to_s,
                                   ocr: ocr
                                 })

          CaseReportAwsText.insert({
                                     court_id: activity.court_id,
                                     case_id:   activity.case_id,
                                     activity_id: activity.activity_id,
                                     text_pdf: text_pdf,
                                     text_ocr: text_ocr,
                                     ocr: ocr,
                                   })
        rescue => e
          p e
        ensure
          File.delete(path_file) if File.exist?(path_file)
        end
      end

      CaseReportAws.insert_all(activitites_to_db) if !activitites_to_db.empty?

      page += 1
      break if activitities.length<limit
    end
  end


end



def get_existing_pdf(links)
  existing_links = []
  rows = CaseReportAws.where(link_to_pdf:links)
  rows.each {|row| existing_links.push(row[:link_to_pdf])}
  existing_links
end

def ocr_pdf(pdf)
  e = Tesseract::Engine.new {|e|
    e.language  = :eng
  }

  puts e.hocr_for(pdf)
end


def get_pdf(limit, court_id)
  p limit
  time_start = Time.new()

  q = 0
  begin
    list_case_type = []
    CaseTypesDivided.where(general_category:'civil').each { |q| list_case_type.push(q[:values]) }
    cases = UsCaseInfoCourts.where(court_id:court_id).where(case_type:list_case_type).limit(limit)

    cobble = Hamster::Scraper::Dasher.new(:using=>:cobble)
    cases.each do |the_case|
      q+=1
      res = cobble.get(the_case[:data_source_url])
      filename = the_case[:data_source_url].split('/')[-1]
      path_file = "pdf_files/#{filename}"
      File.open(path_file, 'wb') { |fp| fp.write(res) }
      keywords_hash, complaint_count = read_pdf(path_file)

      keywords_hash2 = keywords_hash.sort_by { |keyword, count| count }.last(5).reverse

      CaseReport.insert_all([{
                               case_id: the_case[:case_id],
                               case_name: the_case[:case_name],
                               link_pdf_summary: the_case[:data_source_url],
                               top5_matches_summary: keywords_hash2.to_s
                             }])
    end
  rescue => e
    p e
    p 'hi'

  ensure
    time_end = Time.new()
    divide = time_end-time_start
    p q,divide
    File.open('logs/us_case_report_pdf', 'a') { |fp| fp.write("Downloaded cases:#{q}|Time(sec):#{divide}\n") }
  end

end

def get_pdf_42(limit)
  p limit
  time_start = Time.new()

  q = 0
  begin
    list_case_type = []
    CaseTypesDivided.where(general_category:'civil').each { |q| list_case_type.push(q[:values]) }
    cases = UsCaseInfoCourts.where(court_id:42).where(case_type:list_case_type).limit(limit)

    cobble = Hamster::Scraper::Dasher.new(:using=>:cobble)
    cases.each do |the_case|
      q+=1
      res = cobble.get(the_case[:data_source_url])
      filename = the_case[:data_source_url].split('/')[-1]
      path_file = "pdf_files/#{filename}"
      File.open(path_file, 'wb') { |fp| fp.write(res) }
      keywords_hash, complaint_count = read_pdf(path_file)

      keywords_hash2 = keywords_hash.sort_by { |keyword, count| count }.last(5).reverse

      CaseReport.insert_all([{
                               case_id: the_case[:case_id],
                               case_name: the_case[:case_name],
                               link_pdf_summary: the_case[:data_source_url],
                               top5_matches_summary: keywords_hash2.to_s
                             }])
    end
  rescue => e
    p e
    p 'hi'

  ensure
    time_end = Time.new()
    divide = time_end-time_start
    p q,divide
    File.open('logs/us_case_report_pdf', 'a') { |fp| fp.write("Downloaded cases:#{q}|Time(sec):#{divide}\n") }
  end

end




def get_pdf_NY(limit=50)
  p limit
  time_start = Time.new()
  sql= "activity_pdf is not null and activity_decs like 'COMPLAINT%' and activity_decs not like '%Amended%'"
  q = 0
  begin
    list_case_type = []
    CaseTypesDivided.where(general_category:'civil').each { |q| list_case_type.push(q[:values]) }
    cases = NYCaseInfo.where(case_type:list_case_type).limit(limit).map { |row| row[:case_id] }


    cobble = Hamster::Scraper::Dasher.new(:using=>:crowbar, :pc=>1)
    cases.each do |case_id|
      q+=1

      complaint = nil
      activities = NYCaseActivities.where(case_id:case_id)
      activities.each do |activity|
        if activity[:activity_decs].match(/COMPLAINT*/)
          filename = activity[:activity_pdf].split('/')[-1].split('Index=')[-1]
          path_file = "pdf_files/#{filename}"
          @browser = Hamster::Scraper::Dasher.new(activity[:activity_pdf], using: :hammer, hammer_opts: {headless: false, save_path: path_file}).smash

          File.open(path_file, 'wb') { |fp| fp.write(res) }
          complaint = read_pdf(path_file)
          p 'q'
          break
        end
      end

      p complaint
      next
      if !complaint.nil?


      end

      res = cobble.get(the_case[:data_source_url])
      filename = the_case[:data_source_url].split('/')[-1]
      path_file = "pdf_files/#{filename}"
      File.open(path_file, 'wb') { |fp| fp.write(res) }
      keywords_hash = read_pdf(path_file)

      keywords_hash2 = keywords_hash.sort_by { |keyword, count| count }.last(5).reverse

      CaseReport.insert_all([{
                               case_id: the_case[:case_id],
                               case_name: the_case[:case_name],
                               link_pdf_summary: the_case[:data_source_url],
                               top5_matches_summary: keywords_hash2.to_s
                             }])
    end
  rescue => e
    p e
    p 'hi'

  ensure
    time_end = Time.new()
    divide = time_end-time_start
    p q,divide
    File.open('logs/us_case_report_pdf_ny', 'a') { |fp| fp.write("Downloaded cases:#{q}|Time(sec):#{divide}\n") }
  end

end



def open_pdf()
  files = {}

  path = "./projects/project_0994/lib/pdf/"
  Dir.entries(path).each do |file|
    next unless file.match('.pdf')
    p file
    path_file = path+file
    files[file], complaint_count = read_pdf(path_file)

  end
  p files
end

KEYWORDS = ['Asbestos' , 'Attorney Grievance - Misc' , 'Bond Forfeiture' , 'Commercial - Misc' , 'Condemnation / Eminent Domain - Misc' , 'Constitutional' , 'Contract' , 'County Court Order' , 'COVID' , 'Custody' , 'Damages - Misc' , 'Declaratory Judgment' , 'Disciplinary' , 'Domestic Violence' , 'FED' , 'Foreclosure' , 'Foreign Judgment' , 'Forfeiture' , 'Guardianship' , 'Habeas Corpus' , 'Independent Proceedings - Misc' , 'Injunction' , 'Judgment - Other Court' , 'Jury Trial Prayer' , 'Lien' , 'Liens' , 'Matrimonial' , 'Medical, Dental, or Podiatrist Malpractice' , 'Misc Claims' , 'Misc Specific Types' , 'Negligence' , 'Non-Profit/Religious - Misc' , 'Other Equity' , 'Peace Order' , 'Recorded Judgment' , 'Regulation' , 'Replevin' , 'Restitution' , 'Warrant of Inspection' , 'Workers Comp' , 'Writ' , 'Writ of Mandamus' , 'Wrongful Act' , 'Asbestos' , 'Commercial - Misc' , 'Common Pleas' , 'Failure to Pay Rent' , 'Foreclosure' , 'Forfeiture' , 'Guardianship' , 'Insurance' , 'Lis Pendens' , 'Name Change' , 'Peace Order' , 'Small Claims' , 'Small Claims Assessment Review (SCAR)' , 'Workers Comp' , 'Contract' , 'CSEB Confession of Judgment' , 'Large Claims' , 'Small Claims' , 'Condemnation / Eminent Domain - Misc' , 'Foreclosure' , 'Negligence' , 'Right of Redemption' , 'Tax Certiorari' , 'Asbestos' , 'Foreclosure' , 'Medical, Dental, or Podiatrist Malpractice' , 'Motor Vehicle' , 'Negligence' , 'Personal Injury' , 'Product Liability' , 'Professional Malpractice' , 'Workers Comp' , 'Wrongful Act' , 'Child Abuse' , 'Common Pleas' , 'Domestic Violence' , 'Traffic' , 'Child Support' , 'Custody' , 'Divorce' , 'Matrimonial' , 'Paternity' , 'Contempt' , 'Contract' , 'COVID' , 'Foreclosure'].uniq


def read_pdf(path_file)
  reader = PDF::Reader.new(path_file)

  text = ''
  reader.pages.each do |page|
    text += page.text
  end

  how_many_words(text)
end


def how_many_words(text)
  words = {}


  KEYWORDS.each do |keyword|
    next if keyword.in?(words)
    count = text.scan(keyword).size
    words[keyword] = count if count>0
  end

  words

end