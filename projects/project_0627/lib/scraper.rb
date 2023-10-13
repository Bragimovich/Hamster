# frozen_string_literal: true

class Scraper < Hamster::Scraper

  CONTRIBUTION_URL = "https://www.ethics.la.gov/CampaignFinanceSearch/SearchEfilingContributors.aspx"
  EXP_URL = "https://www.ethics.la.gov/CampaignFinanceSearch/SearchEfilingExpenditures.aspx"

  def contribution_landing
    connect_to(CONTRIBUTION_URL)
  end

  def contribution_302(cookie_value, event_validation, view_state, generator, start_date, end_date, parsed_end_date, parsed_start_date)
    body = contribution_302_body(event_validation, view_state, generator, start_date, end_date, parsed_end_date, parsed_start_date)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/SearchEfilingContributors.aspx", headers: get_contributor_headers(cookie_value, CONTRIBUTION_URL), req_body: body, method: :post)
  end

  def contribution_load_page(cookie_value)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/LoadSearch.aspx?SearchPage=SearchResultsByContributions.aspx", headers: get_contributor_headers(cookie_value, "https://www.ethics.la.gov/CampaignFinanceSearch/SearchEFilingContributors.aspx"))
  end

  def contribtions_wait_page(cookie_value)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/PleaseWait.aspx", headers: get_contributor_headers(cookie_value, "https://www.ethics.la.gov/CampaignFinanceSearch/LoadSearch.aspx?SearchPage=SearchResultsByContributions.aspx"))
  end

  def contribution_search_redirect(cookie_value)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/Redirect.aspx?SearchPage=SearchResultsByContributions.aspx", headers: get_contributor_headers(cookie_value, "https://www.ethics.la.gov/CampaignFinanceSearch/LoadSearch.aspx?SearchPage=SearchResultsByContributions.aspx"))
  end

  def contribution_search(cookie_value)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByContributions.aspx", headers: get_contributor_headers(cookie_value, "https://www.ethics.la.gov/CampaignFinanceSearch/Redirect.aspx?SearchPage=SearchResultsByContributions.aspx"))
  end

  def contribution_download_file(cookie_value, event_validation, view_state, generator)
    body = contribution_file_body(view_state, event_validation, generator)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByContributions.aspx", headers: contribution_file_headers(cookie_value), req_body: body, method: :post)
  end

  def expenditure_landing
    connect_to(url: EXP_URL)
  end

  def expenditure_302(cookie_value, event_validation, view_state, generator, start_date, end_date, parsed_end_date, parsed_start_date)
    # body = get_expenditure_res302_body(generator, view_state, event_validation, start_date, parsed_start_date, end_date, parsed_end_date)
    body = expenditure_302_body(generator, view_state, event_validation, start_date, parsed_start_date, end_date, parsed_end_date)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/SearchEfilingExpenditures.aspx", headers: get_expenditure_res302_headers(cookie_value), req_body: body, method: :post)
  end

  def expenditure_load_page(cookie_value)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/LoadSearch.aspx?SearchPage=SearchResultsByExpenditures.aspx", headers: get_expenditure_headers(cookie_value, "https://www.ethics.la.gov/CampaignFinanceSearch/SearchEfilingExpenditures.aspx"))
  end

  def expenditure_wait_page(cookie_value)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/PleaseWait.aspx", headers: get_expenditure_headers(cookie_value, "https://www.ethics.la.gov/CampaignFinanceSearch/LoadSearch.aspx?SearchPage=SearchResultsByExpenditures.aspx"))
  end

  def expenditure_search_redirect(cookie_value)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/Redirect.aspx?SearchPage=SearchResultsByExpenditures.aspx", headers: get_expenditure_headers(cookie_value, "https://www.ethics.la.gov/CampaignFinanceSearch/LoadSearch.aspx?SearchPage=SearchResultsByExpenditures.aspx"))
  end

  def expenditure_search(cookie_value)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByExpenditures.aspx", headers: get_expenditure_headers(cookie_value, "https://www.ethics.la.gov/CampaignFinanceSearch/Redirect.aspx?SearchPage=SearchResultsByExpenditures.aspx"))
  end

  def expenditure_download_file(cookie_value, event_validation, view_state, generator)
    body = expenditure_file_body(event_validation, view_state, generator)
    connect_to(url: "https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByExpenditures.aspx", headers: expenditure_file_headers(cookie_value), req_body: body, method: :post)
  end

  private

  def get_contributor_headers(cookie_value, url)
    {
      "Referer" => url,
      "Cookie" => cookie_value
    }
  end

  def contribution_file_headers(cookie_value)
    {
      "Referer" => "https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByContributions.aspx",
      "Cookie" => cookie_value,
      "Origin" => "https://www.ethics.la.gov"
    }
  end

  def contribution_302_body(event_validation, view_state, generator, start_date, end_date, parsed_end_date, parsed_start_date)
    "__EVENTTARGET=ctl00%24ContentPlaceHolder1%24PerformSearchLinkButton&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape generator}&__EVENTVALIDATION=#{CGI.escape event_validation}&ctl00%24ContentPlaceHolder1%24RadComboBox1=(Type%2Bor%2BSelect%2Ba%2BFiler)&ctl00_ContentPlaceHolder1_RadComboBox1_ClientState=&ctl00%24ContentPlaceHolder1%24NameHiddenField=&ctl00%24ContentPlaceHolder1%24DateFromRadDateInput=#{start_date.gsub('/','%2F')}&ctl00_ContentPlaceHolder1_DateFromRadDateInput_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%22#{parsed_start_date}-00-00-00%22%2C%22valueAsString%22%3A%22#{parsed_start_date}-00-00-00%22%2C%22minDateStr%22%3A%221800-01-01-00-00-00%22%2C%22maxDateStr%22%3A%222099-12-31-00-00-00%22%2C%22lastSetTextBoxValue%22%3A%22#{start_date.gsub('/','%2F')}%22%7D&ctl00%24ContentPlaceHolder1%24DateToRadDateInput=#{end_date.gsub('/','%2F')}&ctl00_ContentPlaceHolder1_DateToRadDateInput_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%22#{parsed_end_date}-00-00-00%22%2C%22valueAsString%22%3A%22#{parsed_end_date}-00-00-00%22%2C%22minDateStr%22%3A%221800-01-01-00-00-00%22%2C%22maxDateStr%22%3A%222099-12-31-00-00-00%22%2C%22lastSetTextBoxValue%22%3A%22#{end_date.gsub('/','%2F')}%22%7D&ctl00%24ContentPlaceHolder1%24ContributionsFromRadNumericTextBox=&ctl00_ContentPlaceHolder1_ContributionsFromRadNumericTextBox_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%22%22%2C%22valueAsString%22%3A%22%22%2C%22minValue%22%3A0%2C%22maxValue%22%3A70368744177664%2C%22lastSetTextBoxValue%22%3A%22%22%7D&ctl00%24ContentPlaceHolder1%24ContributionsToRadNumericTextBox=&ctl00_ContentPlaceHolder1_ContributionsToRadNumericTextBox_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%22%22%2C%22valueAsString%22%3A%22%22%2C%22minValue%22%3A0%2C%22maxValue%22%3A70368744177664%2C%22lastSetTextBoxValue%22%3A%22%22%7D&ctl00%24ContentPlaceHolder1%24CityTextBox=&ctl00%24ContentPlaceHolder1%24StateTextBox=&ctl00%24ContentPlaceHolder1%24ZipTextBox=&ctl00%24ContentPlaceHolder1%24ContNameTextBox=&ctl00%24ContentPlaceHolder1%24DescTextBox=&ctl00%24ContentPlaceHolder1%24OrderByDropDownList="
  end

  def contribution_file_body(view_state, event_validation, generator)
    "__EVENTTARGET=ctl00%24ContentPlaceHolder1%24ExportToCSVLinkButton&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape generator}&__EVENTVALIDATION=#{CGI.escape event_validation}&ctl00%24ContentPlaceHolder1%24GridView1%24ctl01%24GotoPageTextBox=1&ctl00%24ContentPlaceHolder1%24GridView1%24ctl29%24GotoPageTextBox=1"
  end

  def get_expenditure_headers(cookie_value, url)
    {
      "Authority" =>  "www.ethics.la.gov",
      "Accept" =>  "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" =>  "en-US,en;q=0.9",
      "Cache-Control" =>  "max-age=0",
      "Cookie" =>  cookie_value,
      "Referer" =>  url,
      "Sec-Ch-Ua" =>  "\"Chromium\";v=\"110\", \"Not A(Brand\";v=\"24\", \"Google Chrome\";v=\"110\"",
      "Sec-Ch-Ua-Mobile" =>  "?0",
      "Sec-Ch-Ua-Platform" =>  "\"Linux\"",
      "Sec-Fetch-Dest" =>  "document",
      "Sec-Fetch-Mode" =>  "navigate",
      "Sec-Fetch-Site" =>  "same-origin",
      "Sec-Fetch-User" =>  "?1",
      "Upgrade-Insecure-Requests" =>  "1",
      "User-Agent" =>  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
    }
  end

  def get_expenditure_res302_headers(cookie_value)
    {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Authority" =>  "www.ethics.la.gov",
      "Accept" =>  "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" =>  "en-US,en;q=0.9",
      "Cache-Control" =>  "max-age=0",
      "Cookie" => cookie_value,
      "Origin" =>  "https://www.ethics.la.gov",
      "Referer" =>  "https://www.ethics.la.gov/CampaignFinanceSearch/SearchEfilingExpenditures.aspx",
      "Sec-Ch-Ua" =>  "\"Google Chrome\";v=\"111\", \"Not(A:Brand\";v=\"8\", \"Chromium\";v=\"111\"",
      "Sec-Ch-Ua-Mobile" =>  "?0",
      "Sec-Ch-Ua-Platform" =>  "\"Linux\"",
      "Sec-Fetch-Dest" =>  "document",
      "Sec-Fetch-Mode" =>  "navigate",
      "Sec-Fetch-Site" =>  "same-origin",
      "Sec-Fetch-User" =>  "?1",
      "Upgrade-Insecure-Requests" =>  "1",
      "User-Agent" =>  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
    }
  end

  def expenditure_file_headers(cookie_value)
    {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Cookie" => cookie_value,
      "Origin" => "https://www.ethics.la.gov",
      "Referer" => "https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByExpenditures.aspx"
    }
  end

  def expenditure_302_body(generator, view_state, event_validation, start_date, parsed_start_date, end_date, parsed_end_date)
    "__EVENTTARGET=ctl00%24ContentPlaceHolder1%24PerformSearchLinkButton&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{generator}&__EVENTVALIDATION=#{CGI.escape event_validation}&ctl00%24ContentPlaceHolder1%24RadComboBox1=%28Type+or+Select+a+Filer%29&ctl00_ContentPlaceHolder1_RadComboBox1_ClientState=&ctl00%24ContentPlaceHolder1%24NameHiddenField=&ctl00%24ContentPlaceHolder1%24DateFromRadDateInput=#{start_date.gsub('/','%2F')}&ctl00_ContentPlaceHolder1_DateFromRadDateInput_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%22#{parsed_start_date}-00-00-00%22%2C%22valueAsString%22%3A%22#{parsed_start_date}-00-00-00%22%2C%22minDateStr%22%3A%221800-01-01-00-00-00%22%2C%22maxDateStr%22%3A%222099-12-31-00-00-00%22%2C%22lastSetTextBoxValue%22%3A%22#{start_date.gsub('/','%2F')}%22%7D&ctl00%24ContentPlaceHolder1%24DateToRadDateInput=#{end_date.gsub('/','%2F')}&ctl00_ContentPlaceHolder1_DateToRadDateInput_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%22#{parsed_end_date}-00-00-00%22%2C%22valueAsString%22%3A%22#{parsed_end_date}-00-00-00%22%2C%22minDateStr%22%3A%221800-01-01-00-00-00%22%2C%22maxDateStr%22%3A%222099-12-31-00-00-00%22%2C%22lastSetTextBoxValue%22%3A%22#{end_date.gsub('/','%2F')}%22%7D&ctl00%24ContentPlaceHolder1%24ContributionsFromTextBox=&ctl00%24ContentPlaceHolder1%24ContributionsToTextBox=&ctl00%24ContentPlaceHolder1%24CityTextBox=&ctl00%24ContentPlaceHolder1%24StateTextBox=&ctl00%24ContentPlaceHolder1%24ZipTextBox=&ctl00%24ContentPlaceHolder1%24ContNameTextBox=&ctl00%24ContentPlaceHolder1%24DescTextBox=&ctl00%24ContentPlaceHolder1%24OrderByDropDownList=filer_name+ASC+%2C+filer_fname+ASC&ctl00%24ContentPlaceHolder1%24OrderThenByDropDownList=expn_amt+DESC"
  end

  def expenditure_file_body(event_validation, view_state, generator)
    "__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape generator}&__EVENTVALIDATION=#{CGI.escape event_validation}&ctl00%24ContentPlaceHolder1%24ExportToCSVLinkButton=File+is+being+generated.++Please+check+your+downloads."
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end
end
