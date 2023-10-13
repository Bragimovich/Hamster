class Scraper < Hamster::Scraper

  def api_request
    connect_to(url: "https://wabi-west-us-c-primary-api.analysis.windows.net/public/reports/5f43dcde-9d69-4d3a-94b5-4816a0d3a715/modelsAndExploration?preferReadOnlySession=true" , headers: headers)
  end

  def xlsx_request(link)
    connect_to(link)
  end

  private

  def headers
    {
      "Activityid" => "f21ef98b-8b31-610e-a00a-e9d9005a7134",
      "Requestid" => "b7bdd563-5f7e-c1ab-444a-642e697e836e",
      "X-Powerbi-Resourcekey" => "5f43dcde-9d69-4d3a-94b5-4816a0d3a715"
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

end
