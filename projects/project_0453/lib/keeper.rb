# frozen_string_literal: true

require_relative '../models/pdfs'
require_relative '../models/world_cases'

class  Keeper < Hamster::Harvester

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
      record = WorldCases.new
      record.country                = row[:country]
      record.confirmed_cases        = row[:cases]
      record.data_last_updated_est  = row[:updated]
      record.time_of_scrape_est     = row[:time]
      record.date_of_scrape         = row[:date]
      record.data_source_url        = PAGE
      record.save
    end
  end

end
