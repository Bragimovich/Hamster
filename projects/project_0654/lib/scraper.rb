# frozen_string_literal => true
class Scraper < Hamster::Scraper
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def main_request
    connect_to("https://hover.hillsclerk.com/html/case/caseSearch.html")
  end

  def logAnonymouse
    connect_to(url: "https://hover.hillsclerk.com/Account/LogAnonymous", headers: anonymouse_headers, method: :post)
  end

  def search_tab
    connect_to(url: "https://hover.hillsclerk.com/html/search/searchDateFiled.html")
  end

  def activity_pdf_request(doc_id, doc_ver_id, requestor_id)
    body = "DocumentId=#{doc_id}&DocumentVersionId=#{doc_ver_id}&AccessToken=&RequestorGuid=#{requestor_id}"
    headers = pdf_headers
    url = "https://hover.hillsclerk.com/FileManagement/ViewDocument"
    connect_to(url, headers: headers, req_body:body, method: :post)
  end

  def search(requestor_id, start_date, last_date, retries = 50)
    headers = case_headers
    url = "https://hover.hillsclerk.com/Case/Search"
    connect_to(url, headers: headers, req_body:body_search(requestor_id, start_date, last_date), method: :post)
  end

  def search_window(case_id, requestor_id)
    body = case_body(case_id, requestor_id)
    headers = case_headers
    url = "https://hover.hillsclerk.com/CaseInformation/Search"
    connect_to(url, headers: headers, req_body:body, method: :post)
  end

  def case_search(case_id, requestor_id)
    body = case_body(case_id, requestor_id)
    headers = case_headers
    url = "https://hover.hillsclerk.com/CaseInformation/Summary"
    connect_to(url, headers: headers, req_body:body, method: :post)
  end

  def pdf_search(case_id, requestor_id)
    headers = pdf_headers
    body = "CaseNumber=#{case_id}&UserName=&Token=&Guid=#{requestor_id}"
    url = "https://hover.hillsclerk.com/CaseReport/CreateReport"
    connect_to(url, headers: headers, req_body:body, method: :post)
  end

  def party_search(case_id, requestor_id)
    body = case_body(case_id, requestor_id)
    headers = case_headers
    url = "https://hover.hillsclerk.com/CaseParty/CasePartyAtty"
    connect_to(url, headers: headers, req_body:body, method: :post)
  end

  def event_search(case_id, requestor_id)
    body = case_body(case_id, requestor_id)
    headers = case_headers
    url = "https://hover.hillsclerk.com/CaseEvent/Search"
    connect_to(url, headers: headers, req_body:body, method: :post)
  end

  private

  def body_search(requestor_id, start_date, last_date)
    {"UserName":"null","UserBarNumber":"","UserPartyID":"","SearchType":"ByDateFiled","ExtendedSearch":false,"CaseNumber":"","CaseID":0,"CrossReferenceNumber":"","BarNumber":"","PartyID":"","LastName":"","FirstName":"","MiddleName":"","DateOfBirth":"","AttorneyBarNumber":"","UseSoundex":false,"CitationNumber":"","DLNumber":"","CaseStatus":"A","CaseCategory":"","CaseType":"","DateFiledFrom":"#{start_date}","DateFiledTo":"#{last_date}","ErrorFound":false,"RequestorToken":"","RequestorGuid":"#{requestor_id}","UserLastName":"","UserFirstName":"","UserTelephone":"","Status":"A","CaptchaCode":"","SendParameters":{"draw":1,"columns":[{"data":"caseID","name":"","searchable":true,"orderable":false,"search":{"value":"","regex":false}},{"data":"caseID","name":"","searchable":true,"orderable":false,"search":{"value":"","regex":false}},{"data":"caseNumber","name":"","searchable":true,"orderable":false,"search":{"value":"","regex":false}},{"data":"citationNumber","name":"","searchable":true,"orderable":false,"search":{"value":"","regex":false}},{"data":"caseStyle","name":"","searchable":true,"orderable":false,"search":{"value":"","regex":false}},{"data":"caseStatus","name":"","searchable":true,"orderable":false,"search":{"value":"","regex":false}},{"data":"caseFiledOn","name":"","searchable":true,"orderable":false,"search":{"value":"","regex":false}},{"data":"caseTypeDescription","name":"","searchable":true,"orderable":false,"search":{"value":"","regex":false}}],"order":[{"column":0,"dir":"asc"}],"start":0,"length":500,"search":{"value":"","regex":false}},"RequestorUserName":""}.to_json
  end

  def case_body(case_id, requestor_id)
    {"UserName":"","BarNumber":"","SearchType":"ByCase","CaseNumber":"#{case_id}","CrossReferenceNumber":"","LastName":"","FirstName":"","MiddleName":"","DateOfBirth":"","CitationNumber":"","CaseStatus":"A","CaseCategory":"","CaseType":"","DateFiledFrom":"","DateFiledTo":"","ErrorFound":false,"RequestorToken":"","RequestorGuid":"#{requestor_id}","NewSearch":1,"RequestorUserName":""}.to_json
  end

  def pdf_headers
    {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Origin" => "https://hover.hillsclerk.com",
      "Referer" => "https://hover.hillsclerk.com/html/case/searchResults.html",
      }
  end

  def case_headers
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json, text/javascript, */*; q=0.01",
      "Origin" => "https://hover.hillsclerk.com",
      "Referer" => "https://hover.hillsclerk.com/html/case/searchResults.html",
     }
  end

  def anonymouse_headers
    {
      "Accept" => "*/*",
      "Origin" => "https =>//hover.hillsclerk.com",
      "Referer" => "https =>//hover.hillsclerk.com/html/case/caseSearch.html",
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304, 302, 307].include?(response.status)
    end
    response
  end
end
