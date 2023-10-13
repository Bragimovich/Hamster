# frozen_string_literal: true

require 'zip'

class Scraper < Hamster::Scraper
  def scrape_csv_zip_page
    headers = {
        accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        accept_language: 'en-US,en;q=0.5',
        connection: 'keep-alive',
        upgrade_insecure_requests: '1',
        'Upgrade-Insecure-Requests': '1'
    }

    connect_to(url: 'https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Pages/FullCampaignFinanceExport.aspx?SortField=LinkFilenameNoMenu&SortDir=Desc',
               headers: headers,
               method: :get)
  end

  def download_zip_file(url, zip_file_name)
    connect_to(url, method: :get_file, filename: "#{storehouse}/store/#{zip_file_name}")
  end

  def unzip_csv_files(zip_file_name)
    begin
      Zip::File.open("#{storehouse}/store/#{zip_file_name}") do |zip_file|
        zip_file.each do |entry|
          p entry.name
          entry.extract("#{storehouse}/store/#{entry.name.gsub('2020/', '').gsub('.txt', '.csv')}")
        end
      end
    rescue StandardError => e
      p e
      p e.backtrace
      return false
    end

    true
  end

  def remove_local_csv_files
    Dir.glob("#{storehouse}/store/*.csv").each { |file| File.delete(file) }
  end

  def move_zip_to_trash(zip_file_name)
    File.rename("#{storehouse}/store/#{zip_file_name}",
                "#{storehouse}/store/#{Time.now.day}_#{Time.now.month}_#{zip_file_name}")
    FileUtils.mv("#{storehouse}/store/#{Time.now.day}_#{Time.now.month}_#{zip_file_name}",
                 "#{storehouse}/trash/#{Time.now.day}_#{Time.now.month}_#{zip_file_name}")
  end

  def remove_all_files_in_store
    Dir.glob("#{storehouse}/store/*").each { |file| File.delete(file) }
  end

  private

  # The functionality of downloading candidates doesn't work in current version

  def scrape_candidates
    headers = {
        accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        accept_language: 'en-US,en;q=0.5',
        connection: 'keep-alive',
        upgrade_insecure_requests: '1'
    }

    response = connect_to(url: 'https://www.campaignfinanceonline.pa.gov/pages/CFReportSearch.aspx',
                          headers: headers,
                          method: :get)

    p response
    p response.body
    p cookie = response.headers['set-cookie']

    doc = Nokogiri::HTML(response.body)
    p viewstate = viewstate_parse(doc).gsub('/////', '')
    p viewstategenerator = viewstategenerator_parse(doc)
    # p eventvalidation = eventvalidation_parse(doc)
    p eventvalidation = eventvalidation_parse(doc)[0...-2]

    headers = {
        accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        accept_language: 'en-US,en;q=0.5',
        connection: 'keep-alive',
        upgrade_insecure_requests: '1',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': cookie,
        'Host': 'www.campaignfinanceonline.pa.gov',
        'Origin': 'https://www.campaignfinanceonline.pa.gov',
        'Referer': 'https://www.campaignfinanceonline.pa.gov/pages/CFReportSearch.aspx',
        'Upgrade-Insecure-Requests': '1'
    }

    response = connect_to(url: 'https://www.campaignfinanceonline.pa.gov/pages/CFReportSearch.aspx',
                          req_body: "__EVENTTARGET=&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{viewstate}&__VIEWSTATEGENERATOR=#{viewstategenerator}&__EVENTVALIDATION=#{eventvalidation}&ctl00%24ContentPlaceHolder1%24txtSearchName=&ctl00%24ContentPlaceHolder1%24rbGroupSearch=rbContrRec&ctl00%24ContentPlaceHolder1%24txtContributorNameCR=&ctl00%24ContentPlaceHolder1%24txtRecipientNameCR=aaa&ctl00%24ContentPlaceHolder1%24txtEmployerNameCR=&ctl00%24ContentPlaceHolder1%24txtContributorNameCM=&ctl00%24ContentPlaceHolder1%24txtRecipientNameCM=&ctl00%24ContentPlaceHolder1%24txtEmployerNameCM=&ctl00%24ContentPlaceHolder1%24txtCandidateNameEX=&ctl00%24ContentPlaceHolder1%24txtRecipientEX=&ctl00%24ContentPlaceHolder1%24txtDescriptionEX=&ctl00%24ContentPlaceHolder1%24txtCandidateDB=&ctl00%24ContentPlaceHolder1%24txtCreditorDB=&ctl00%24ContentPlaceHolder1%24txtDescriptionDB=&ctl00%24ContentPlaceHolder1%24txtCandidateRP=&ctl00%24ContentPlaceHolder1%24txtRecipientRP=&ctl00%24ContentPlaceHolder1%24txtDescriptionRP=&ctl00%24ContentPlaceHolder1%24hdnYear=2022&ctl00%24ContentPlaceHolder1%24ddlElectionYear=2022&ctl00%24ContentPlaceHolder1%24chklistElection%240=on&ctl00%24ContentPlaceHolder1%24chkAllCycles=on&ctl00%24ContentPlaceHolder1%24ddlOffice=-1&ctl00%24ContentPlaceHolder1%24ddlDistrict=-1&ctl00%24ContentPlaceHolder1%24chkListParty%244=on&ctl00%24ContentPlaceHolder1%24txtCity=&ctl00%24ContentPlaceHolder1%24ddlState=PA&ctl00%24ContentPlaceHolder1%24txtZip=&ctl00_ContentPlaceHolder1_FromDatePicker_clientState=%7C0%7C012022-1-1-0-0-0-0%7C%7C%5B%5B%5B%5B%5D%5D%2C%5B%5D%2C%5B%5D%5D%2C%5B%7B%7D%2C%5B%5D%5D%2C%22012022-1-1-0-0-0-0%22%5D&ctl00_ContentPlaceHolder1_ToDatePicker_clientState=%7C0%7C012022-12-31-0-0-0-0%7C%7C%5B%5B%5B%5B%5D%5D%2C%5B%5D%2C%5B%5D%5D%2C%5B%7B%7D%2C%5B%5D%5D%2C%22012022-12-31-0-0-0-0%22%5D&ctl00%24ContentPlaceHolder1%24txtMinAmt=&ctl00%24ContentPlaceHolder1%24txtMaxAmt=&ctl00%24ContentPlaceHolder1%24btnSearch=Search&ctl00__ig_def_dp_cal_clientState=%7C0%7C11%2C2021%2C01%2C2021%2C1%2C1%7C%7C%5B%5Bnull%2C%5B%5D%2Cnull%5D%2C%5B%7B%7D%2C%5B%5D%5D%2C%2211%2C2021%2C01%2C2021%2C1%2C1%22%5D&ctl00%24_IG_CSS_LINKS_=..%2FApp_Themes%2FTheme1%2Fcontentslider.css%7C..%2FApp_Themes%2FTheme1%2FStyleSheet.css%7C..%2Fig_res%2FDefault%2Fig_monthcalendar.css%7C..%2Fig_res%2FDefault%2Fig_texteditor.css%7C..%2Fig_res%2FDefault%2Fig_shared.css",
                          headers: headers,
                          method: :post)
    p response
    p response.body

    # headers = {
    #     accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    #     accept_language: 'en-US,en;q=0.5',
    #     connection: 'keep-alive',
    #     upgrade_insecure_requests: '1',
    #     'Cookie': cookie
    # }
    #
    # response = connect_to(url: 'https://www.campaignfinanceonline.pa.gov/pages/CFReportSearchResults.aspx',
    #                       headers: headers,
    #                       method: :get)
    #
    # p response
    # p response.body
    # p cookie = response.headers['set-cookie']
    p Time.now
  end

  def viewstate_parse(doc)
    begin
      doc.css('input[name="__VIEWSTATE"]').first['value']
    rescue StandardError => e
      p e
      p e.backtrace
    end
  end

  def viewstategenerator_parse(doc)
    begin
      doc.css('input[name="__VIEWSTATEGENERATOR"]').first['value']
    rescue StandardError => e
      p e
      p e.backtrace
    end
  end

  def eventvalidation_parse(doc)
    begin
      doc.css('input[name="__EVENTVALIDATION"]').first['value']
    rescue StandardError => e
      p e
      p e.backtrace
    end
  end
end
