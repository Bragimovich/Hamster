# frozen_string_literal: true

class Scraper < Hamster::Scraper

  MAIN_URL = 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchByName.aspx'

  def get_main_page_response
    connect_to(url: MAIN_URL, method: :get)
  end

  def get_search_page_response(event_val, view_state, view_state_gen, cookie_value)
    body = get_search_page_body(event_val, view_state, view_state_gen)
    connect_to(url: MAIN_URL, method: :post, headers: get_headers(cookie_value), req_body: body)
  end

  def get_result_page_response(cookie_value)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchResults.aspx'
    connect_to(url: url, method: :get, headers: get_headers(cookie_value))
  end

  def candidate_inner_page_post(view_state, view_state_gen, cookie, id)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchResults.aspx'
    body = get_candidate_inner_body(view_state, view_state_gen, id)
    connect_to(url: url, method: :post, req_body: body, headers: get_headers(cookie))
  end

  def pdf_post_request(id, cookie)
    url = "https://www.ethics.la.gov/CampaignFinanceSearch/ShowEFormPDF.aspx?Save=PDF&ReportID=#{id}"
    body = get_pdf_body(id)
    connect_to(url: url, method: :post, req_body: body, headers: get_headers(cookie))
  end

  def get_view_filer_page(id, cookie)
    url = "https://www.ethics.la.gov/CampaignFinanceSearch/ViewEFiler.aspx?FilerID=#{id}"
    connect_to(url: url, method: :get, headers: get_headers(cookie))
  end

  def get_post_view_filer_page_cont(event_val, view_state, view_state_gen, id, cookie)
    url = "https://www.ethics.la.gov/CampaignFinanceSearch/ViewEFiler.aspx?FilerID=#{id}"
    body = get_view_filer_post_body_cont(event_val, view_state, view_state_gen)
    connect_to(url: url, method: :post, headers: get_headers(cookie), req_body: body)
  end

  def get_post_view_filer_page_exp(event_val, view_state, view_state_gen, id, cookie)
    url = "https://www.ethics.la.gov/CampaignFinanceSearch/ViewEFiler.aspx?FilerID=#{id}"
    body = get_view_filer_post_body_exp(event_val, view_state, view_state_gen)
    connect_to(url: url, method: :post, headers: get_headers(cookie), req_body: body)
  end

  def get_contribution_load_page(cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/LoadSearch.aspx?SearchPage=SearchResultsByContributions.aspx'
    connect_to(url: url, method: :get, headers: get_headers(cookie))
  end

  def get_expenditure_load_page(cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/LoadSearch.aspx?SearchPage=SearchResultsByExpenditures.aspx'
    connect_to(url: url, method: :get, headers: get_headers(cookie))
  end

  def get_wait_page(cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/PleaseWait.aspx'
    connect_to(url: url, method: :get, headers: get_headers(cookie))
  end

  def get_contribution_redirect_page(cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/Redirect.aspx?SearchPage=SearchResultsByContributions.aspx'
    connect_to(url: url, method: :get, headers: get_headers(cookie))
  end

  def get_expenditure_redirect_page(cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/Redirect.aspx?SearchPage=SearchResultsByExpenditures.aspx'
    connect_to(url: url, method: :get, headers: get_headers(cookie))
  end

  def get_contribution_result_page(cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByContributions.aspx'
    connect_to(url: url, method: :get, headers: get_headers(cookie))
  end

  def get_expenditure_result_page(cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByExpenditures.aspx'
    connect_to(url: url, method: :get, headers: get_headers(cookie))
  end

  def pagination_post_request(view_state, view_state_gen, cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchResults.aspx'
    body = get_pagination_body(view_state, view_state_gen)
    connect_to(url: url, method: :post, req_body: body, headers: get_headers(cookie), timeout: 60)
  end

  def download_pdf(id, cookie)
    url = "https://eap.ethics.la.gov/CFSearch/#{id}"
    connect_to(url: url, method: :get, headers: get_headers(cookie), proxy_filter: @proxy_filter, timeout: 200)
  end

  def download_contribution_csv(event_val, view_state, view_state_gen, cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByContributions.aspx'
    body = get_contribution_csv_body(event_val, view_state, view_state_gen)
    connect_to(url: url, method: :post, req_body: body, headers: get_headers(cookie), proxy_filter: @proxy_filter, timeout: 200)
  end

  def download_expenditure_csv(event_val, view_state, view_state_gen, cookie)
    url = 'https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByExpenditures.aspx'
    body = get_expenditure_csv_body(event_val, view_state, view_state_gen)
    connect_to(url: url, method: :post, req_body: body, headers: get_headers(cookie), proxy_filter: @proxy_filter, timeout: 200)
  end

  private

  def get_search_page_body(event_val, view_state, view_state_gen)
    "__EVENTTARGET=ctl00%24ContentPlaceHolder1%24SearchLinkButton&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape view_state_gen}&__EVENTVALIDATION=#{CGI.escape event_val}&ctl00%24ContentPlaceHolder1%24NameTextBox="
  end

  def get_view_filer_post_body_cont(event_val, view_state, view_state_gen)
    "__EVENTTARGET=ctl00%24ContentPlaceHolder1%24ViewAllContributions&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape view_state_gen}&__EVENTVALIDATION=#{CGI.escape event_val}"
  end

  def get_view_filer_post_body_exp(event_val, view_state, view_state_gen)
    "__EVENTTARGET=ctl00%24ContentPlaceHolder1%24ViewAllExpendituresLinkButton&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape view_state_gen}&__EVENTVALIDATION=#{CGI.escape event_val}"
  end

  def get_candidate_inner_body(view_state, view_state_gen, id)
    "__EVENTTARGET=ctl00%24ContentPlaceHolder1%24ResultsGridView%24#{id}%24FullNameLinkButton&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape view_state_gen}&ctl00%24ContentPlaceHolder1%24ResultsGridView%24ctl01%24GotoPageTextBox=1&ctl00%24ContentPlaceHolder1%24ResultsGridView%24ctl24%24GotoPageTextBox=1"
  end

  def get_contribution_csv_body(event_val, view_state, view_state_gen)
    "__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape view_state_gen}&__EVENTVALIDATION=#{CGI.escape event_val}&ctl00%24ContentPlaceHolder1%24ExportToCSVLinkButton=File+is+being+generated.++Please+check+your+downloads."
  end

  def get_expenditure_csv_body(event_val, view_state, view_state_gen)
    "__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape view_state_gen}&__EVENTVALIDATION=#{CGI.escape event_val}&ctl00%24ContentPlaceHolder1%24ExportToCSVLinkButton=File+is+being+generated.++Please+check+your+downloads."
  end

  def get_pagination_body(view_state, view_state_gen)
    "__EVENTTARGET=&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape view_state_gen}&ctl00%24ContentPlaceHolder1%24ResultsGridView%24ctl01%24GotoPageTextBox=1&ctl00%24ContentPlaceHolder1%24ResultsGridView%24ctl24%24GotoPageTextBox=1&ctl00%24ContentPlaceHolder1%24ResultsGridView%24ctl24%24NextLinkButton=Next"
  end

  def get_pdf_body(id)
    "Save=PDF&ReportID=#{id}"
  end

  def get_headers(cookie_value)
    { 
      "Cookie" => cookie_value
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200,304,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    Hamster.logger.info 'Response status: '.indent(1, "\t").green
    status = response&.status
    Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
  end

end
