# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    super
    @get_info = ->(array, key) { array.select{|item| item[2]&.match(/#{key}/i)}&.first }
  end

  def hidden_field_data(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    parsed_doc.xpath("//input[@type='hidden']").each do |input_tag|
      form_data[input_tag.at_xpath("./@name")&.value] = input_tag.at_xpath("./@value")&.value
    end
    form_data
  end

  def receipt_year_form_data(response_body, year)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    year_list = [nil,2023,2022,2021,2020,2019,2018,2017,2016]
    parsed_doc.xpath("//input").each do |input_tag|
      input_name = input_tag.at_xpath("./@name")&.value&.strip
      input_value = input_tag.at_xpath("./@value")&.value&.strip
      if input_name.presence
        form_data[input_name] = input_value || ''
      end
    end

    form_data['RadScriptManager1'] = 'cfis_ajxPanelPanel|cmbFilingYear'
    form_data['RadScriptManager1_TSM'] = ';;System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35:en-US:16997a38-7253-4f67-80d9-0cbcc01b3057:ea597d4b:b25378d2;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:16e4e7cd:ed16cbdc:f7645509:24ee1bba:f46195d3:2003d0b8:1e771326:aa288e2d:b7778d6c:7c926187:8674cba1:c08e9f8a:a51ee93e:59462f1:e085fe68:874f8ea2:19620875:490a9d4e:bd8f85e4;'
    form_data['__EVENTTARGET'] = 'cmbFilingYear'
    form_data['__EVENTARGUMENT'] = JSON.generate({"Command":"Select","Index":year_list.index(year)})
    form_data['txtContributorName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['txtFirstName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['cmbFilingYear'] = year
    form_data['cmbFilingYear_ClientState'] = JSON.generate({"logEntries":[],"value":"#{year}","text":"#{year}","enabled":true,"checkedIndices":[],"checkedItemsTextOverflows":false})
    form_data['cmbFilingCalenderName'] = 'Special Pre-Election  2023 (Assembly District 24)'
    form_data['txtOccupation_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['txtGabid_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['dtpDateStart_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['NtxAmountStart_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":0,"maxValue":70368744177664})
    form_data['NtxAmountEnd_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":0,"maxValue":70368744177664})
    form_data['dtpDateEnd_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['__ASYNCPOST'] = true
    form_data['RadAJAXControlID'] = 'cfis_ajxPanel'

    form_data
  end

  def receipt_search_form_data(response_body, year)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    parsed_doc.xpath("//input").each do |input_tag|
      input_name = input_tag.at_xpath("./@name")&.value&.strip
      input_value = input_tag.at_xpath("./@value")&.value&.strip
      if input_name.presence
        form_data[input_name] = input_value || ''
      end
    end
    
    hidden_field_data = parse_hidden_field(response_body)
    form_data['RadScriptManager1'] = 'cfis_ajxPanelPanel|btnSearch'
    form_data['RadScriptManager1_TSM'] = ';;System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35:en-US:16997a38-7253-4f67-80d9-0cbcc01b3057:ea597d4b:b25378d2;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:16e4e7cd:ed16cbdc:f7645509:24ee1bba:f46195d3:2003d0b8:1e771326:aa288e2d:b7778d6c:7c926187:8674cba1:c08e9f8a:a51ee93e:59462f1:e085fe68:874f8ea2:19620875:490a9d4e:bd8f85e4;'
    form_data['txtContributorName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['txtFirstName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['cmbFilingYear'] = year
    form_data['cmbFilingCalenderName'] = 'All Filing Periods'
    form_data['cmbFilingCalenderName_ClientState'] = JSON.generate({"logEntries":[],"value":"","text":"All Filing Periods","enabled":true,"checkedIndices":[],"checkedItemsTextOverflows":false})
    form_data['txtOccupation_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['txtGabid_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['dtpDateStart_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['NtxAmountStart_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":0,"maxValue":70368744177664})
    form_data['NtxAmountEnd_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":0,"maxValue":70368744177664})
    form_data['dtpDateEnd_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['__LASTFOCUS'] = @get_info.call(hidden_field_data, 'LASTFOCUS')[3]
    form_data['__EVENTTARGET'] = @get_info.call(hidden_field_data, 'EVENTTARGET')[3]
    form_data['__EVENTARGUMENT'] = @get_info.call(hidden_field_data, 'EVENTARGUMENT')[3]
    form_data['__VIEWSTATE'] = @get_info.call(hidden_field_data, 'VIEWSTATE')[3]
    form_data['__VIEWSTATEGENERATOR'] = @get_info.call(hidden_field_data, 'VIEWSTATEGENERATOR')[3]
    form_data['__ASYNCPOST'] = true
    form_data['btnSearch.x'] = rand(3..80)
    form_data['btnSearch.y'] = rand(2..20)
    form_data['RadAJAXControlID'] = 'cfis_ajxPanel'
    form_data
  end

  def range_list(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    parsed_doc.xpath("//div[@id='cmbExportRecords_DropDown']/div/ul[@class='rcbList']/li").map(&:text)
  end

  def receipt_csv_download_data(response_body, year, range)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    parsed_doc.xpath("//input").each do |input_tag|
      input_name = input_tag.at_xpath("./@name")&.value&.strip
      input_value = input_tag.at_xpath("./@value")&.value&.strip
      if input_name.presence
        form_data[input_name] = input_value || ''
      end
    end
    hidden_field_data = parse_hidden_field(response_body)
    form_data['RadScriptManager1_TSM'] = ';;System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35:en-US:16997a38-7253-4f67-80d9-0cbcc01b3057:ea597d4b:b25378d2;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:16e4e7cd:ed16cbdc:f7645509:24ee1bba:f46195d3:2003d0b8:1e771326:aa288e2d:b7778d6c:7c926187:8674cba1:c08e9f8a:a51ee93e:59462f1:e085fe68:874f8ea2:19620875:490a9d4e:bd8f85e4;'
    form_data['txtContributorName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['txtFirstName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['cmbFilingYear'] = year
    form_data['cmbFilingCalenderName'] = 'All Filing Periods'
    form_data['cmbFilingCalenderName_ClientState'] = JSON.generate({"logEntries":[],"value":"","text":"All Filing Periods","enabled":true,"checkedIndices":[],"checkedItemsTextOverflows":false})
    form_data['txtOccupation_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['txtGabid_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['dtpDateStart_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['NtxAmountStart_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":0,"maxValue":70368744177664})
    form_data['NtxAmountEnd_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":0,"maxValue":70368744177664})
    form_data['dtpDateEnd_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['__LASTFOCUS'] = @get_info.call(hidden_field_data, 'LASTFOCUS')[3]
    form_data['__EVENTTARGET'] = @get_info.call(hidden_field_data, 'EVENTTARGET')[3] 
    form_data['__EVENTARGUMENT'] = @get_info.call(hidden_field_data, 'EVENTARGUMENT')[3] 
    form_data['__VIEWSTATE'] = @get_info.call(hidden_field_data, 'VIEWSTATE')[3]
    form_data['__VIEWSTATEGENERATOR'] = @get_info.call(hidden_field_data, 'VIEWSTATEGENERATOR')[3] 
    form_data['__ASYNCPOST'] = true
    form_data['cmbExportRecords'] = range
    if range == '1-65000'
      form_data['cmbExportRecords_ClientState'] = ''
    else
      form_data['cmbExportRecords_ClientState'] = JSON.generate({"logEntries":[],"value":"","text":range,"enabled":true,"checkedIndices":[],"checkedItemsTextOverflows":false})
    end
    form_data['cmdTextextra.x'] = 0
    form_data['cmdTextextra.y'] = 0
    form_data
  end

  def expense_year_form_data(response_body, year)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    year_list = [nil,2023,2022,2021,2020,2019,2018,2017,2016]
    parsed_doc.xpath("//input").each do |input_tag|
      input_name = input_tag.at_xpath("./@name")&.value&.strip
      input_value = input_tag.at_xpath("./@value")&.value&.strip
      if input_name.presence
        form_data[input_name] = input_value || ''
      end
    end

    form_data['RadScriptManager1'] = 'cfis_ajxPanelPanel|cmbFilingYear'
    form_data['RadScriptManager1_TSM'] = ';;System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35:en-US:16997a38-7253-4f67-80d9-0cbcc01b3057:ea597d4b:b25378d2;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:16e4e7cd:f7645509:ed16cbdc:24ee1bba:f46195d3:2003d0b8:1e771326:aa288e2d:b7778d6c:7c926187:8674cba1:c08e9f8a:a51ee93e:59462f1:e085fe68:874f8ea2:19620875:490a9d4e:bd8f85e4;;;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:58366029'
    form_data['__EVENTTARGET'] = 'cmbFilingYear'
    form_data['__EVENTARGUMENT'] = JSON.generate({"Command":"Select","Index":year_list.index(year)})
    form_data['txtPayeeName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['cmbFilingYear'] = year
    form_data['cmbFilingYear_ClientState'] = JSON.generate({"logEntries":[],"value":"#{year}","text":"#{year}","enabled":true,"checkedIndices":[],"checkedItemsTextOverflows":false})
    form_data['cmbFilingCalenderName'] = 'Special Pre-Election  2023 (Assembly District 24)'
    form_data['dtpFromDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_ClientState'] = JSON.generate({"minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['txtStartAmt_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":-70368744177664,"maxValue":70368744177664})
    form_data['txtEndAmt_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":-70368744177664,"maxValue":70368744177664})
    form_data['dtpCommunicationFrmDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpCommunicationToDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpCommunicationToDate_ClientState'] = JSON.generate({"minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['__ASYNCPOST'] = true
    form_data['RadAJAXControlID'] = 'cfis_ajxPanel'
    form_data
  end

  def expense_search_form_data(response_body, year)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    parsed_doc.xpath("//input").each do |input_tag|
      input_name = input_tag.at_xpath("./@name")&.value&.strip
      input_value = input_tag.at_xpath("./@value")&.value&.strip
      if input_name.presence
        form_data[input_name] = input_value || ''
      end
    end
    
    hidden_field_data = parse_hidden_field(response_body)
    form_data['RadScriptManager1'] = 'cfis_ajxPanelPanel|btnSearch'
    form_data['RadScriptManager1_TSM'] = ';;System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35:en-US:16997a38-7253-4f67-80d9-0cbcc01b3057:ea597d4b:b25378d2;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:16e4e7cd:f7645509:ed16cbdc:24ee1bba:f46195d3:2003d0b8:1e771326:aa288e2d:b7778d6c:7c926187:8674cba1:c08e9f8a:a51ee93e:59462f1:e085fe68:874f8ea2:19620875:490a9d4e:bd8f85e4;;;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:58366029'
    form_data['cmbFilingYear'] = year
    form_data['cmbFilingCalenderName'] = 'All Filing Periods'
    form_data['txtPayeeName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['cmbFilingCalenderName_ClientState'] = JSON.generate({"logEntries":[],"value":"","text":"All Filing Periods","enabled":true,"checkedIndices":[],"checkedItemsTextOverflows":false})
    form_data['dtpFromDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_ClientState'] = JSON.generate({"minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['txtStartAmt_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":-70368744177664,"maxValue":70368744177664})
    form_data['txtEndAmt_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":-70368744177664,"maxValue":70368744177664})
    form_data['dtpCommunicationFrmDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpCommunicationToDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpCommunicationToDate_ClientState'] = JSON.generate({"minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['__EVENTTARGET'] = @get_info.call(hidden_field_data, 'EVENTTARGET')[3]
    form_data['__EVENTARGUMENT'] = @get_info.call(hidden_field_data, 'EVENTARGUMENT')[3]
    form_data['__VIEWSTATE'] = @get_info.call(hidden_field_data, 'VIEWSTATE')[3]
    form_data['__VIEWSTATEGENERATOR'] = @get_info.call(hidden_field_data, 'VIEWSTATEGENERATOR')[3]
    form_data['__ASYNCPOST'] = true
    form_data['btnSearch.x'] = rand(3..80)
    form_data['btnSearch.y'] = rand(2..20)
    form_data['RadAJAXControlID'] = 'cfis_ajxPanel'
    form_data
  end

  def expense_csv_download_data(response_body, year)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    parsed_doc.xpath("//input").each do |input_tag|
      input_name = input_tag.at_xpath("./@name")&.value&.strip
      input_value = input_tag.at_xpath("./@value")&.value&.strip
      if input_name.presence
        form_data[input_name] = input_value || ''
      end
    end
    hidden_field_data = parse_hidden_field(response_body)

    form_data['RadScriptManager1_TSM'] = ';;System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35:en-US:16997a38-7253-4f67-80d9-0cbcc01b3057:ea597d4b:b25378d2;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:16e4e7cd:f7645509:ed16cbdc:24ee1bba:f46195d3:2003d0b8:1e771326:aa288e2d:b7778d6c:7c926187:8674cba1:c08e9f8a:a51ee93e:59462f1:e085fe68:874f8ea2:19620875:490a9d4e:bd8f85e4;;;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:58366029'
    form_data['cmbFilingYear'] = year
    form_data['cmbFilingCalenderName'] = 'All Filing Periods'
    form_data['txtPayeeName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['dtpFromDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_ClientState'] = JSON.generate({"minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['txtStartAmt_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":-70368744177664,"maxValue":70368744177664})
    form_data['txtEndAmt_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minValue":-70368744177664,"maxValue":70368744177664})
    form_data['dtpCommunicationFrmDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1980-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpCommunicationToDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpCommunicationToDate_ClientState'] = JSON.generate({"minDateStr":"1-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['__EVENTTARGET'] = @get_info.call(hidden_field_data, 'EVENTTARGET')[3]
    form_data['__EVENTARGUMENT'] = @get_info.call(hidden_field_data, 'EVENTARGUMENT')[3]
    form_data['__VIEWSTATE'] = @get_info.call(hidden_field_data, 'VIEWSTATE')[3]
    form_data['__VIEWSTATEGENERATOR'] = @get_info.call(hidden_field_data, 'VIEWSTATEGENERATOR')[3]
    form_data['__ASYNCPOST'] = true
    form_data['cmdTextextra.x'] = 0
    form_data['cmdTextextra.y'] = 0
    form_data
  end

  def registrant_search_form_data(response_body, registrant_type)
    reg_type = registrant_type[0]
    reg_value = registrant_type[1]
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    parsed_doc.xpath("//input").each do |input_tag|
      input_name = input_tag.at_xpath("./@name")&.value&.strip
      input_value = input_tag.at_xpath("./@value")&.value&.strip
      if input_name.presence
        form_data[input_name] = input_value || ''
      end
    end
    form_data['RadScriptManager1'] = 'cfis_ajxPanelPanel|btnSearch'
    form_data['RadScriptManager1_TSM'] = ';;System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35:en-US:16997a38-7253-4f67-80d9-0cbcc01b3057:ea597d4b:b25378d2;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:16e4e7cd:ed16cbdc:f7645509:24ee1bba:f46195d3:2003d0b8:1e771326:aa288e2d:b7778d6c:7c926187:8674cba1:c08e9f8a:a51ee93e:59462f1;;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:58366029'
    form_data['cmbType'] = reg_type
    form_data['cmbType_ClientState'] = JSON.generate({"logEntries":[], "value": reg_value, "text": reg_type,"enabled":true,"checkedIndices": [],"checkedItemsTextOverflows":false})
    form_data['txtCandidateName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['txtGABID_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['dtpFromDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpFromDate_ClientState'] = JSON.generate({"minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_ClientState'] = JSON.generate({"minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['__ASYNCPOST'] = true
    form_data['btnSearch.x'] = rand(3..80)
    form_data['btnSearch.y'] = rand(2..20)
    form_data['RadAJAXControlID'] = 'cfis_ajxPanel'
    form_data.delete('status')
    form_data
  end

  def registrant_list(response_body)
    data = []
    parsed_doc = Nokogiri::HTML.parse(response_body)
    parsed_doc.xpath("//table[@class='rgMasterTable']/tbody/tr").each do |tr|
      committee_id = tr.at_xpath("./td[2]/span").text
      href_match = tr.at_xpath("./td[3]/a/@href").value.match(/\('(grd.*Label)',/)
      data << [committee_id, href_match[1]]
    end
    data
  end

  def parse_page_info(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    parsed_doc.xpath("//div[@id='divFooter']/table/tr/td")&.last&.text
  end

  def registrant_page_params(response_body, reg_type, page)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    parsed_doc.xpath("//input").each do |input_tag|
      input_name = input_tag.at_xpath("./@name")&.value&.strip
      input_value = input_tag.at_xpath("./@value")&.value&.strip
      if input_name.presence
        form_data[input_name] = input_value || ''
      end
    end
    form_data['RadScriptManager1_TSM'] = ';;System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35:en-US:16997a38-7253-4f67-80d9-0cbcc01b3057:ea597d4b:b25378d2;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:16e4e7cd:ed16cbdc:f7645509:24ee1bba:f46195d3:2003d0b8:1e771326:aa288e2d:b7778d6c:7c926187:8674cba1:c08e9f8a:a51ee93e:59462f1;;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:58366029'
    form_data['cmbType'] = reg_type
    form_data['txtCandidateName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['txtGABID_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['dtpFromDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpFromDate_ClientState'] = JSON.generate({"minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_ClientState'] = JSON.generate({"minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['__EVENTTARGET'] = 'pager1'
    form_data['__EVENTARGUMENT'] = page
    form_data.delete('status')
    form_data
  end

  def registrant_pdf_download_data(response_body, reg_type, href_target)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    parsed_doc.xpath("//input").each do |input_tag|
      input_name = input_tag.at_xpath("./@name")&.value&.strip
      input_value = input_tag.at_xpath("./@value")&.value&.strip
      if input_name.presence
        form_data[input_name] = input_value || ''
      end
    end
    hidden_field_data = parse_hidden_field(response_body)
    form_data['RadScriptManager1_TSM'] = ';;System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35:en-US:16997a38-7253-4f67-80d9-0cbcc01b3057:ea597d4b:b25378d2;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:16e4e7cd:ed16cbdc:f7645509:24ee1bba:f46195d3:2003d0b8:1e771326:aa288e2d:b7778d6c:7c926187:8674cba1:c08e9f8a:a51ee93e:59462f1;;Telerik.Web.UI, Version=2012.3.1308.35, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:847349a7-61ac-4c43-803e-aa1cc5b6cced:58366029'
    form_data['cmbType'] = reg_type
    form_data['txtCandidateName_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['txtGABID_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":""})
    form_data['dtpFromDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpFromDate_ClientState'] = JSON.generate({"minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_dateInput_ClientState'] = JSON.generate({"enabled":true,"emptyMessage":"","validationText":"","valueAsString":"","minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['dtpToDate_ClientState'] = JSON.generate({"minDateStr":"1960-01-01-00-00-00","maxDateStr":"2099-12-31-00-00-00"})
    form_data['__EVENTTARGET'] = href_target
    form_data['__EVENTARGUMENT'] = @get_info.call(hidden_field_data, 'EVENTARGUMENT')[3] if @get_info.call(hidden_field_data, 'EVENTARGUMENT')
    form_data['__VIEWSTATE'] = @get_info.call(hidden_field_data, 'VIEWSTATE')[3] if @get_info.call(hidden_field_data, 'VIEWSTATE')
    form_data['__VIEWSTATEGENERATOR'] = @get_info.call(hidden_field_data, 'VIEWSTATEGENERATOR')[3] if @get_info.call(hidden_field_data, 'VIEWSTATEGENERATOR')
    form_data['__LASTFOCUS'] = @get_info.call(hidden_field_data, 'LASTFOCUS')[3] if @get_info.call(hidden_field_data, 'LASTFOCUS')

    form_data
  end
  
  def parse_hidden_field(response_body)
    parsed_data = []
    data_str = response_body || ''

    while data_str.length.positive?
      # Length
      splitter_idx = data_str.index('|')
      return parsed_data if splitter_idx.nil?

      length_str = data_str[0, splitter_idx]
      length = length_str.to_i
      splitter_idx += 1
      data_str = data_str[splitter_idx ..] || ''

      # Type
      splitter_idx = data_str.index('|')
      return parsed_data if splitter_idx.nil?

      type_str = data_str[0, splitter_idx]
      splitter_idx += 1
      data_str = data_str[splitter_idx..] || ''

      # Name
      splitter_idx = data_str.index('|')
      return parsed_data if splitter_idx.nil?

      name_str = data_str[0, splitter_idx]
      splitter_idx += 1
      data_str = data_str[splitter_idx..] || ''

      # Value
      value_str = data_str[0, length]
      splitter_idx = length + 1
      data_str = data_str[splitter_idx..] || ''

      parsed_data << [length, type_str, name_str, value_str] if type_str == 'hiddenField'
    end

    parsed_data
  end
end
