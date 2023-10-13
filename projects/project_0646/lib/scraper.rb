# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def main_request
    url = 'https://www.courts.mo.gov/casenet/cases/filingDateSearch.do'
    connect_to(url: url,method: :get,proxy_filter: @proxy_filter)
  end

  def get_inner_response(url,cookie)
    connect_to(url: url,method: :get,proxy_filter: @proxy_filter,headers: get_headers(cookie),timeout: 60)
  end

  def main_request_post(start_date,start_record)
    url = 'https://www.courts.mo.gov/casenet/cases/filingDateSearch.do'
    body = get_main_body(start_date,start_record)
    connect_to(url: url,req_body: body,method: :post,proxy_filter: @proxy_filter)
  end

  private

  def get_main_body(start_date,start_record)
    "inputVO.caseType=All&inputVO.startDate=#{CGI.escape start_date}&inputVO.errFlag=N&inputVO.caseTypeDesc=&inputVO.selectionAction=search&inputVO.courtId=CT22&inputVO.courtDesc=22nd+Judicial+Circuit&inputVO.countyDesc=All&inputVO.countyCode=&inputVO.locationDesc=All&inputVO.locationCode=&inputVO.caseStatus=A&inputVO.type=CT&inputVO.startingRecord=#{start_record}&inputVO.totalRecords=457&inputVO.subAction=search"
  end

  def get_headers(cookie)
    {
      "Accept" => "application/json, text/javascript, */*; q=0.01",
      "Accept-Language" => "en-US,en;q=0.9",
      "Connection" => "keep-alive",
      "Cookie" => cookie,
      "Referer" => "https://www.courts.mo.gov/cnet/cases/newHeader.do?inputVO.caseNumber=1622-FC01709-01&inputVO.courtId=CT22",
      "Sec-Fetch-Dest" => "empty",
      "Sec-Fetch-Mode" => "cors",
      "Sec-Fetch-Site" => "same-origin",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
      "X-Requested-With" => "XMLHttpRequest",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\""
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end
  
  def reporting_request(response)
    Hamster.logger.info 'Response status: '.indent(1, "\t").green
    status = response&.status
    Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
  end

end
