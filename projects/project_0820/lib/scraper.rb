require_relative "../lib/manager.rb"

class Scraper <  Hamster::Scraper

  URL = "http://iml.slsheriff.org/IML"

  def hit_main_page
    Hamster.connect_to(URL)
  end

  def hit_result_page(cookie, request_body)
    body = request_body
    headers = {}
    headers["Cookie"] = cookie
    Hamster.connect_to(url:URL, method: :post, req_body: body, headers: headers )
  end

  def prepare_payload(iteration: nil, page_type: nil, current_start: nil, sysID: nil, imgSysID: nil)
    unless iteration.nil?
      if iteration == 1
        return "flow_action=searchbyname"
      else
        return "flow_action=next&currentStart=#{current_start}"
      end
    else
      return "flow_action=edit&sysID=#{sysID}&imgSysID=#{imgSysID}"
    end
  end

end
