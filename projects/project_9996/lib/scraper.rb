# frozen_string_literal: true
require_relative '../models/us_courts_case_summary_court_links'
require_relative 'case_summary_keeper'

class NYCourtsCaseSummaryPDF < Hamster::Scraper
  def initialize
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 200)
  end

  def transfer_ny_courts_case_summary_to_pdf(courts)
    begin
    puts "Start".green

    courts = courts.class == Array ? courts.flatten : [courts]
    courts.to_a.each do |court|
      begin
      court_data = USCourtsCaseSummaryLinks.where(["court_id = :court_id", { court_id: court }])
      rescue => e
      end

      next if !court_data

      min_id = court_data.minimum(:id)
      max_id = court_data.maximum(:id)

      while min_id <= max_id do
        counter = 0
        court_id = court
        begin
        case_data = USCourtsCaseSummaryLinks.find_by(id: min_id)
        USCourtsCaseSummaryLinks.clear_active_connections!
        #proceed_case = USCasePDFAWS.find_by(source_link: case_data[:data_source_url])
        #USCasePDFAWS.clear_active_connections!
        # if proceed_case
        #min_id += 1
        #next
        #end

        rescue => e
        end

        if !case_data
          min_id += 1
          next
        end

        case_id = case_data[:case_id]
        data_source_url = case_data[:data_source_url]

        suffix = data_source_url.split('/')[-2, 2].join('_').sub(/[.]html?$/, '').gsub('?', '_').gsub(/=|&/, '')
        html_key = "us_courts_expansion_#{court_id}_court_#{suffix}.html"
        pdf_key = "us_courts_expansion_#{court_id}_court_#{suffix}.pdf"

        puts "Proceed case: Court_id - #{court_id}, case_id - #{case_id}".green

        begin
        begin
        hammer = Dasher.new(using: :hammer, proxy_filter: @proxy_filter, save_pdf: true, pdf_name: pdf_key)
        page = hammer.get(data_source_url)
        rescue => e
          hammer.close
          hammer = nil
          counter += 1
          retry  if counter < 10
          puts "#{e} | #{e.backtrace}"
        ensure
          hammer.close
          hammer = nil
        end
        rescue => e
          sleep(120)
          hammer = nil
        end

        min_id += 1
        next if !page

        # start_id = page&.index('<div id="UCS_Header">')
        # end_id = page&.index('<div id="pageContent">')
        #next if !start_id || !end_id
        #page[start_id, end_id - start_id] = ''
        # aws_html_link = @s3.put_file(page, html_key, metadata={ url: data_source_url })

        # pdf = File.open("#{storehouse}store/#{pdf_key}", 'r')
        # aws_link = @s3.put_file(pdf, pdf_key, metadata={ url: data_source_url })

        # NYCaseSummaryKeeper.new.store_data(court_id, case_id, aws_link, aws_html_link, data_source_url)
      end
    end
    puts "Successfull".green
    Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - NY Transfer case summary to PDF completed successfully!"
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      puts msg
      Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - NY Transfer case summary to PDF failed - #{msg}"
    end
  end
end

