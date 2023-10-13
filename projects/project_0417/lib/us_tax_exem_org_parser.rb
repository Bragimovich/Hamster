
class USTaxExemOrgParser < Hamster::Parser

  def initialize(**page)
    super
    @html = Nokogiri::HTML(page[:html])
    @xml  = Nokogiri::XML(page[:xml])
  end

  def parse_orgs
    return nil unless table = @html.at('table tbody')

    table.css('tr').map do |tr|
      {
        name: tr.at('td').text,
        organization: tr.css('td')[1].text,
        total_annual_salary: tr.css('td')[2].text.gsub('$', '').gsub(',', ''),
        link: "https://nonprofitlight.com#{tr.at('td a')['href']}"
      }
    end
  end

  def parse_xml_link
    xml_link = @html.css('.col-md-8 a').last['href']
    return nil unless xml_link.match?(/.xml$/)

    xml_link
  end

  def parse_xml
    name           = @xml.at('BusinessName').nil? ? @xml.at('Filer Name').text.gsub(/\s{2,}/, ' ').strip : @xml.at('BusinessName').text.gsub(/\s{2,}/, ' ').strip

    total_revenue  = @xml.at('CYTotalRevenueAmt').text.to_i       if @xml.at('CYTotalRevenueAmt')
    total_revenue  = @xml.at('TotalRevenueAmt').text.to_i         if total_revenue.nil? && @xml.at('TotalRevenueAmt')
    total_revenue  = @xml.at('TotalRevenueCurrentYear').text.to_i if total_revenue.nil? && @xml.at('TotalRevenueCurrentYear')

    total_expenses = @xml.at('CYTotalExpensesAmt').text.to_i       if @xml.at('CYTotalExpensesAmt')
    total_expenses = @xml.at('TotalExpensesAmt').text.to_i         if total_expenses.nil? && @xml.at('TotalExpensesAmt')
    total_expenses = @xml.at('TotalExpensesCurrentYear').text.to_i if total_expenses.nil? && @xml.at('TotalExpensesCurrentYear')

    net_assets     = @xml.at('NetAssetsOrFundBalancesEOYAmt').text.to_i if @xml.at('NetAssetsOrFundBalancesEOYAmt')
    net_assets     = @xml.at('NetAssetsOrFundBalancesEOY').text.to_i    if net_assets.nil? && @xml.at('NetAssetsOrFundBalancesEOY')

    address_tag    = @xml.at('Filer USAddress') || @xml.at('ReturnData USAddress') || @xml.at('PreparerFirmUSAddress')
    address        = address_tag.text.strip
    address_noko   = address_tag.children.map { |tag| tag unless tag.text.strip.empty? }.compact
    state          = address_noko[-2].text
    city           = address_noko[-3].text.capitalize
    zip            = address_noko[-1].text
    street_address = address.split(' ').map(&:capitalize)
    idx = []
    street_address.each_with_index { |i, index| idx << index if i == city.split(' ')[0] }
    street_address = street_address[0..idx[-1]-1].join(' ')

    activity_desc  = @xml.at('ActivityOrMissionDesc').text if @xml.at('ActivityOrMissionDesc')
    mission_desc   = @xml.at('MissionDesc').text if @xml.at('MissionDesc')
    desc           = @xml.at('ReturnData Desc').text if @xml.at('ReturnData Desc')
    desc_lvl2      = @xml.at('ProgSrvcAccomActy2Grp Desc').text if @xml.at('ProgSrvcAccomActy2Grp Desc')
    desc_lvl3      = @xml.at('ProgSrvcAccomActy3Grp Desc').text if @xml.at('ProgSrvcAccomActy3Grp Desc')

    executives_blocks = [@xml.css('Form990PartVIISectionAGrp'), @xml.css('OfficerDirectorTrusteeEmplGrp'),
                        @xml.css('Form990PartVIISectionA')]

    executives = executives_blocks.flatten.map do |i|
      exec_name  = i.at('PersonNm').text if i.at('PersonNm')
      exec_name  = i.at('BusinessNameLine1Txt').text if exec_name.nil? && i.at('BusinessNameLine1Txt')
      exec_name  = i.at('NamePerson').text if exec_name.nil? && i.at('NamePerson')
      exec_name  = i.at('BusinessNameLine1').text if exec_name.nil? && i.at('BusinessNameLine1')
      hours_week = i.at('AverageHoursPerWeekRt').text if i.at('AverageHoursPerWeekRt')
      hours_week = i.at('AverageHoursPerWeek').text if hours_week.nil? && i.at('AverageHoursPerWeek')
      hours_week = i.at('AverageHoursPerWeekRltdOrgRt').text if hours_week.nil? && i.at('AverageHoursPerWeekRltdOrgRt')
      hours_week = i.at('ReportableCompFromRltdOrgAmt').text if hours_week.nil? && i.at('ReportableCompFromRltdOrgAmt')
      hours_week = i.at('AverageHrsPerWkDevotedToPosRt').text if hours_week.nil? && i.at('AverageHrsPerWkDevotedToPosRt')
      total_salary = i.at('ReportableCompFromOrgAmt').text if i.at('ReportableCompFromOrgAmt')
      total_salary = i.at('AverageHoursPerWeekRltdOrgRt').text if total_salary.nil? && i.at('AverageHoursPerWeekRltdOrgRt')
      total_salary = i.at('CompensationAmt').text if total_salary.nil? && i.at('CompensationAmt')
      total_salary = i.at('ReportableCompFromOrganization').text if total_salary.nil? && i.at('ReportableCompFromOrganization')
      title = i.at('TitleTxt')&.text
      title = i.at('Title')&.text if title.nil?

      { name: exec_name,
        title: title,
        hours_week: hours_week,
        total_salary: total_salary }
    end

    { name: name, total_revenue: total_revenue, total_expenses: total_expenses, net_assets: net_assets,
      address: address, state: state, city: city, zip: zip, activity_desc: activity_desc, mission_desc: mission_desc,
      desc_lvl1: desc, desc_lvl2: desc_lvl2, desc_lvl3: desc_lvl3, street_address: street_address, executives: executives }
  rescue StandardError => e
    puts "#{e} | #{e.full_message}"
    Hamster.report(to: 'Eldar Eminov', message: e, use: :both)
  end
end
