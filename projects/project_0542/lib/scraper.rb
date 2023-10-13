class Scraper < Hamster::Scraper
  def initialize(**option)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
  end
  def get_json(page)
    data          = []
    page_size     = 100
    headers       = { Content_Type: 'application/json; charset=UTF-8',
                          Password: '12B631CC-5922-4EF8-8978-23CF2F32EA8D',
                            Userid: 'publictools'
                      }
    link          = "https://api-proxy.azbar.org/MemberSearch/Search/?PageSize=#{page_size}&Page=#{page}&RequestorEntityNumber=undefined"
    form_data     = {"FirstName": "",
                       "MiddleName": "",
                       "LastName": "%",
                       "Firm": "",
                       "City": "",
                       "State": "",
                       "Zip": "",
                       "County": "",
                       "LanguageCode": "",
                       "LawSchool": "",
                       "Section": "",
                       "Specialization": "",
                       "IncludeDeceased": true,
                       "FuzzySearch": true,
                       "JurisdictionCode": "",
                       "LegalNeed": "",
                       "IsLpSearch": false
                      }.to_json
    json           = connect_to(   link,
                       proxy_filter: @proxy_filter,
                       ssl_verify:   false,
                       method:       :post,
                       req_body:     form_data,
                       headers:      headers)
    lawyers        = JSON.parse(json.body)

    pages          = (lawyers['Result']['TotalCount'].to_f / lawyers['Result']['PageSize']).round(half: :up)
    entity_numbers = lawyers['Result']['Results'].map { |lawyer| lawyer['EntityNumber'] }
    entity_numbers.each do |entity_number|
      source = "https://api-proxy.azbar.org/MemberSearch/Search?EntityNumber=#{entity_number}&RequestorEntityNumber=undefined&{}"
      lawyer = JSON.parse(connect_to(source, headers: headers).body)
      next if lawyer['Result'].nil? || lawyer['Result'].empty?

      data << lawyer['Result']
    end
    page == pages ? nil : data
  rescue => e
    Hamster.logger.error(e.full_message)
  end
end
