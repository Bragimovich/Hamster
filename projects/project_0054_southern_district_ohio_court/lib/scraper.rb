require_relative 'file_splitter'
require_relative '../models/us_case_info'

class Scraper < Hamster::Scraper
  include FileSplitter

  SUBFOLDER = 'southern_district_ohio_court/'
  JSON_SUBFOLDER = 'json/'

  def download_files
    # peon.throw_trash
    files_to_trash

    login_data = {
        username:   'mc3866',
        password:   'Record04',
        court_id:   'ohsd',
    }
    years = (2016..Time.now.year).to_a
    court = Pacer.new(**login_data)

    years.each do |year|
      court.cases_links(from: "1/1/#{year}", to: "12/31/#{year}") do |el|
        unless el[:is_open]
          court_case = UsCaseInfo.find_by(case_id: el[:id])
          unless court_case.nil?
            next if court_case.status_as_of_date.include? 'Closed'
          end
        end

        begin
          body = court.docket_page(el[:link]).body
          url = el[:link].href.gsub(/^iquery.pl\?/, '')
          status = el[:is_open] ? 'Open' : 'Closed'
          save_files(body, url, status, el[:id], year)
        rescue StandardError => e
        end
      end
    end
  end

  def download_files_for_year(year)
    files_to_trash_by_year(year)

    login_data = {
      username:   'mc3866',
      password:   'Record04',
      court_id:   'ohsd',
    }
    court = Pacer.new(**login_data)
    json_hash = {}

    Dir.mkdir("#{ENV['HOME']}/HarvestStorehouse/project_0054/store/#{JSON_SUBFOLDER}") unless File.exists?(
      "#{ENV['HOME']}/HarvestStorehouse/project_0054/store/#{JSON_SUBFOLDER}"
    )
    json_storage_path = "#{ENV['HOME']}/HarvestStorehouse/project_0054/store/#{JSON_SUBFOLDER}cases#{year}.json"

    court.cases_links(from: "1/1/#{year}", to: "12/31/#{year}") do |el|
      json_hash[el[:id]] = el[:is_open] unless el[:id].empty?
      unless el[:is_open]
        court_case = UsCaseInfo.find_by(case_id: el[:id])
        unless court_case.nil?
          next if court_case.status_as_of_date.include? 'Closed'
        end
      end

      begin
        body = court.docket_page(el[:link]).body
        url = el[:link].href.gsub(/^iquery.pl\?/, '')
        status = el[:is_open] ? 'Open' : 'Closed'
        save_files(body, url, status, el[:id], year)
      rescue StandardError => e
      end
    end

    court = nil # clean memory

    File.open(json_storage_path,"w") do |f|
      f.write(JSON.pretty_generate(json_hash))
    end

    json_hash = nil # clean memory
  end

  private

  def save_files(html, url, status, case_id, year)
    subfolder = 'southern_district_ohio_court/'
    peon.put content: create_content(html, url, status, case_id), file: "#{year}#{Time.now.to_i.to_s}", subfolder: subfolder
  end

  def files_to_trash_by_year(year)
    trash_folder = 'southern_district_ohio_court/'
    peon.list.each do |zip|
      peon.give_list(subfolder: zip).each do |file|
        peon.move(file: file, from: zip, to: trash_folder) if file[0..3] == year.to_s
      end
    end
  end
end