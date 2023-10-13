# frozen_string_literal: true

class Scraper < Connect
  def initialize
    super
  end

  def main_page
    headers = {
      'Accept' => 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language' => 'ru,en;q=0.9,en-US;q=0.8',
      'Connection' => 'keep-alive',
      'Content-Type' => 'application/json; charset=utf-8',
      'Origin' => 'https://checkbook.ohio.gov',
      'Referer' => 'https://checkbook.ohio.gov/Salaries/State.aspx',
      'sec-ch-ua-mobile' => '?0',
      'sec-ch-ua-platform' => 'Linux',
      'Sec-Fetch-Dest' => 'empty',
      'Sec-Fetch-Mode' => 'cors',
      'Sec-Fetch-Site' => 'same-origin',
      'X-Requested-With' => 'XMLHttpRequest'

    }
    page = connect(url: "https://checkbook.ohio.gov/WebServices/Tableau.asmx/GetUniqueId", method: :post, headers: headers)
    token = JSON.parse(page.body)

    header = {
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Encoding' => 'gzip, deflate, br',
      'Accept-Language' => 'ru,en;q=0.9,en-US;q=0.8',
      'Connection' => 'keep-alive',
      'Host' => 'analytics.das.ohio.gov',
      'Referer' => 'https://checkbook.ohio.gov/',
      'sec-ch-ua' => '"Chromium";v="110", "Not A(Brand";v="24", "Google Chrome";v="110"',
      'sec-ch-ua-mobile' => '?0',
      'sec-ch-ua-platform' => 'Linux',
      'Sec-Fetch-Dest' => 'iframe',
      'Sec-Fetch-Mode' => 'navigate',
      'Sec-Fetch-Site' => 'same-site',
      'Upgrade-Insecure-Requests' => '1'
    }

    page2 = connect(url: "https://analytics.das.ohio.gov/trusted/#{token['d']}/t/INTBUD/views/Payroll/AgencyPayroll?Year=2022&:refresh=yes&:embed=y&:showVizHome=n&:tabs=n&:toolbar=n&:apiID=host0",headers: header)
    location = page2.get_fields('location').join
    connect(url: location)
  end

  def save_file(year)
    connect(url: "https://analytics.das.ohio.gov/t/INTBUD/views/Payroll/EmployeePayroll/EmployeePayrollCrosstab.csv?Agency=&Year=#{year}", method: :get_file, filename: storehouse + "store/employee_#{year}.csv")
  end
end
