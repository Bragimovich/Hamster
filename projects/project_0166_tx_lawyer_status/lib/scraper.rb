class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def scraper
    url = "https://www.texasbar.com/AM/Template.cfm?Section=Find_A_Lawyer&Template=/CustomSource/MemberDirectory/Search_Form_Client_Main.cfm&Find=0"
    connect_to(url)
  end

  def download_inner_pages(link)
    connect_to(link)
  end

  def connect_to_form_data(name, page = 1)
    form_data = get_form_data(name, page)
    form_data = form_data.to_a.map { |val| val[0] + "=" + val[1] }.join("&")
    url = "https://www.texasbar.com/AM/Template.cfm?Section=Find_A_Lawyer&Template=/CustomSource/MemberDirectory/Result_form_client.cfm"
    response  = connect_to(url: url, req_body: form_data, proxy_filter: @proxy_filter, method: :post)
    response.body
  end

  private

  def get_form_data(name, page)
    {
      "BarCardNumber" => "",
      "BarDistrict"   => "",
      "ButtonName"    => "Page",
      "CompanyName"   => "",
      "Country"       => "",
      "County"        => "",
      "FilterName"    => "",
      "FirstName"     => "",
      "InformalName"  => "",
      "LastName"      => "",
      "MaxNumber"     => "25",
      "Name"          => name,
      "PPlCityName"   => "",
      "Page"          => page.to_s,
      "Region"        => "",
      "ShowOnlyTypes" => "",
      "ShowPrinter"   => "1",
      "SortName"      => "",
      "Start"         => "",
      "State"         => "",
      "Submitted"     => "1",
      "TYLADistrict"  => "",
      "Zip"           => "",
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
