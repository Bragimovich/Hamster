class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def connect_bill_search_get
    connect_to("https://capitol.texas.gov/Search/BillSearch.aspx")
  end

  def connect_bill_search_post(cookie_value, previous_value, view_state, generator, legislature_value)
    body = main_page_body(previous_value, view_state, generator, legislature_value)
    connect_to("https://capitol.texas.gov/Search/BillSearch.aspx", headers: headers(cookie_value), req_body: body, method: :post)
  end

  def pagination(cookie_value, legislature, page, location, id)
    connect_to("https://capitol.texas.gov/Search/BillSearchResults.aspx?CP=#{page+1}&shCmte=False&shComp=False&shSumm=False&NSP=1&SPL=False&SPC=False&SPA=True&SPS=False&Leg=#{legislature[0]}&Sess=#{legislature[1]}&ChamberH=True&ChamberS=True&BillType=B;JR;CR;R;;;&AuthorCode=&SponsorCode=&ASAndOr=O&IsPA=True&IsJA=False&IsCA=False&IsPS=True&IsJS=False&IsCS=False&CmteCode=&CmteStatus=&OnDate=&FromDate=&ToDate=&FromTime=&ToTime=&LastAction=False&Actions=S000;S001;H001;&AAO=O&Subjects=&SAO=&TT=&ID=#{id}",headers: headers(cookie_value), ssl_verify: false)
  end

  def connect_bill(link)
    connect_to(link)
  end

  def connect_bill_outer(location, cookie)
    url = ("https://capitol.texas.gov#{location}")
    connect_to(url, headers: headers(cookie))
  end

  def connect_commeties_main_page(chamber, array = nil, legis = nil)
    if array.nil?
      response = connect_to("https://capitol.texas.gov/Committees/CommitteesMbrs.aspx?Chamber="+chamber)
    else
      body = make_legis_body(array, legis)
      10.times do
        response = Hamster.connect_to(url: "https://capitol.texas.gov/Committees/CommitteesMbrs.aspx?Chamber="+chamber, req_body: body, method: :post)
        return response if response&.status && [200, 304 ,302].include?(response.status)
      end
    end
    response
  end

  def scrap_inner_legis_page(link)
    connect_to("https://capitol.texas.gov/Committees/#{link}")
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

  def make_legis_body(array, legis)
    generator, view_state, event_validation = array
    "__EVENTTARGET=ddlLegislature&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape generator}&__EVENTVALIDATION=#{CGI.escape event_validation}&ddlLegislature=#{CGI.escape legis.to_s}"
  end

  def main_page_body(previous_value, view_state, generator, legislature_value)
    "__EVENTTARGET=&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape generator}&__PREVIOUSPAGE=#{CGI.escape previous_value}&cboLegSess=#{CGI.escape legislature_value}&chkHouse=on&chkSenate=on&chkB=on&chkJR=on&chkCR=on&chkR=on&chkAll=on&btnSearch=Search&usrLegislatorsFolder%24cboAuthor=&usrLegislatorsFolder%24chkPrimaryAuthor=on&usrLegislatorsFolder%24authspon=rdoOr&usrLegislatorsFolder%24cboSponsor=&usrLegislatorsFolder%24chkPrimarySponsor=on&usrSubjectsFolder%24subjectandor=rdoOr&usrSubjectsFolder%24txtCodes=&usrCommitteesFolder%24cboCommittee=&usrCommitteesFolder%24status=rdoStatusBoth&usrActionsFolder%24actionandor=rdoOr&usrActionsFolder%24txtCodes=&usrActionsFolder%24lastaction=rdoLastActionNo&usrActionsFolder%24dtActionOnDate=&usrActionsFolder%24dtActionFromDate=&usrActionsFolder%24dtActionToDate="
  end

  def headers(cookie)
    {
    "Content-Type" => "application/x-www-form-urlencoded",
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Connection" => "keep-alive",
    "Cookie" => cookie,
    "Origin" => "https://capitol.texas.gov",
    "Pragma" => "no-cache",
    "Referer" => "https://capitol.texas.gov/Search/BillSearch.aspx",
    "Upgrade-Insecure-Requests" => "1",
    }
  end

end
