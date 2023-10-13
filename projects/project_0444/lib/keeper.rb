# frozen_string_literal: true

require_relative '../models/pdfs'
require_relative '../models/usa_cases'

class Keeper < Hamster::Harvester
  def store_pdf(pdf_data)
    pdf = Pdfs.new
    pdf.date                = pdf_data[:date]
    pdf.pdf_link            = pdf_data[:link]
    pdf.usa_or_world_image  = pdf_data[:type]
    pdf.data_source_url     = pdf_data[:url]
    pdf.save
  end

  def store_cases(cases_data)
    cases_data.each do |row|
      record = USACases.new
      record.state                  = row[:state]
      record.confirmed_cases        = row[:cases]
      record.data_last_updated_est  = row[:updated]
      record.time_of_scrape_est     = row[:time]
      record.date_of_scrape         = row[:date]
      record.csv_source_link        = row[:csv]
      record.data_source_url        = CDC_PAGE
      record.save
    end
  end

  def update_aws_links(aws_links)
    aws_links.each do |item|
      Pdfs.where(pdf_link: item[:file]).last&.update({pdf_link: item[:aws_link]})
      USACases.where(csv_source_link: item[:file]).update_all(csv_source_link: item[:aws_link])
    end
  end
end
