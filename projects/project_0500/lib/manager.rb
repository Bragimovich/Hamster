require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require 'pry'

class Manager < Hamster::Scraper

  BASE_URL = "https://www.mywsba.org/PersonifyEbusiness/LegalDirectory.aspx"
  URL_FOR_SEARCH = "https://attorneyinfo.aoc.arkansas.gov/info/attorney/attorneysearch.aspx"
  BASE_URL_FOR_USER_PROFILE = "https://www.mywsba.org/PersonifyEbusiness/LegalDirectory/LegalProfile.aspx"
  SUB_FOLDER = 'lawyerStatus500'
  ROUSTER_URL = "https://attorneyinfo.aoc.arkansas.gov/info/Attorney/Attorney_Roster.aspx"

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @file_path = storehouse + 'store/rouster.csv'
    @csv_file_name = 'MainRoutster.gz'
  end

  def download
    download_main_rouster_file

    response , _ = @scraper.get_request(URL_FOR_SEARCH)
    param_hash = @parser.get_required_form_data_variables(response.body)
    @cookie = response.headers["set-cookie"]

    # next post request with form data got from get request above
    form_data = __prepare_form_data(param_hash)
    response , status = @scraper.post_request(URL_FOR_SEARCH,form_data,@cookie,false)
    return if status != 200
    download_details_page(response.body)
    save_file(response,"page-1.gz")

    script_manager_tsm_last_portion = ":;Telerik.Web.UI, Version=2020.1.219.45, Culture=neutral, PublicKeyToken=121fae78165ba3d4:en-US:bb184598-9004-47ca-9e82-5def416be84b:58366029;"
    i = 2
    while true
      event_target = @parser.get_event_target_given_page_number(response.body,i)
      if event_target == nil
        # check for the next page
        event_target = @parser.get_next_page(response.body)
      end
      
      if event_target == nil
        break
      end
      
      view_state,view_state_generator,request_verification_token = @parser.parse_html_constants(response.body)
      page_instance_key = @parser.get_page_instance_key(response.body)
      client_context = param_hash[:client_context]

      hash = {
        view_state: view_state,
        view_state_gen: view_state_generator,
        page_instance_key: page_instance_key,
        request_verification_token: request_verification_token,
        client_context: client_context,
        script_manager_tsm: param_hash[:script_manager_tsm] + script_manager_tsm_last_portion,
        manager: event_target,
        event_target: event_target
      }

      form_data = __prepare_form_data(hash)  
      response , _ = @scraper.post_request( URL_FOR_SEARCH, form_data , @cookie, false)
      file_name = "page-#{i}.gz"
      download_details_page(response.body)
      save_file(response,file_name)
      i += 1
    end
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def __prepare_form_data(param_hash)
    manager = CGI.escape param_hash[:manager]
    client_context = CGI.escape param_hash[:client_context]
    requestVerificationToken = CGI.escape param_hash[:request_verification_token]
    page_instance_key = CGI.escape param_hash[:page_instance_key]
    event_target = CGI.escape param_hash[:event_target]
    view_state = CGI.escape param_hash[:view_state]
    view_genrator = CGI.escape param_hash[:view_state_gen]
    script_manager_tsm = CGI.escape param_hash[:script_manager_tsm]
    
    form_data = ""
    form_data += "ctl01$ScriptManager1=ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ListerPanel|#{manager}&"
    form_data += "__WPPS=s&"
    form_data += "__ClientContext=#{client_context}&"
    form_data += "__CTRLKEY=&"
    form_data += "__SHIFTKEY=&"
    form_data += "ctl01_ScriptManager1_TSM=#{script_manager_tsm}&"
    form_data += "PageInstanceKey=#{page_instance_key}&"
    form_data += "__RequestVerificationToken=#{requestVerificationToken}&"
    form_data += "TemplateUserMessagesID=ctl01_TemplateUserMessages_ctl00_Messages&"
    form_data += "PageIsDirty=0&"
    form_data += "IsControlPostBackctl01$HeaderLogo$HeaderLogoSpan=1&"
    form_data += "IsControlPostBackctl01$SocialNetworking$SocialNetworking=1&"
    form_data += "__EVENTTARGET=#{event_target}&"
    form_data += "__EVENTARGUMENT=&"
    form_data += "IsControlPostBackctl01$SearchField=1&"
    form_data += "NavMenuClientID=ctl01_TemplateMainNavigation_Primary_NavMenu&"
    form_data += "IsControlPostBackctl01$TemplateBody$WebPartManager1$gwpciNewContentHtml2_c4c40438a6a241cd8b4755b1602474fc$ciNewContentHtml2_c4c40438a6a241cd8b4755b1602474fc=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$WebPartManager1$gwpciNewContentHtml_a38b4f51d17f460888c4ebedc1f9f62e$ciNewContentHtml_a38b4f51d17f460888c4ebedc1f9f62e=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage1=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPageFooter1=1&"
    form_data += "IsControlPostBackctl01$FooterArea$FooterContent=1&"
    form_data += "__VIEWSTATE=#{view_state}&"
    form_data += "__VIEWSTATEGENERATOR=#{view_genrator}&"
    form_data += "ctl01_TemplateMainNavigation_Primary_NavMenu_ClientState=&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$mHiddenCacheQueryId=&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$mHiddenQueryCached=False&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$ctl01=189d6367-9f81-4623-95c8-8b4dcff434c7.FS2.FL1&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$Input0$TextBox1=%&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$ctl04=189d6367-9f81-4623-95c8-8b4dcff434c7.FS2.FL2&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$Input1$TextBox1=&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$ctl07=189d6367-9f81-4623-95c8-8b4dcff434c7.FS2.FL3&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$Input2$TextBox1=&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$ctl10=189d6367-9f81-4623-95c8-8b4dcff434c7.FS2.FL4&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$Input3$TextBox1=&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$ctl13=189d6367-9f81-4623-95c8-8b4dcff434c7.FS2.FL8&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$Input4$TextBox1=&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$HiddenKeyField1=code_ID&"
    form_data += "ctl01_GenericWindow_ClientState=&"
    form_data += "ctl01_ObjectBrowser_ClientState=&"    
    form_data += "ctl01_ObjectBrowserDialog_ClientState=&"
    form_data += "ctl01_WindowManager1_ClientState=&"
    form_data += "__ASYNCPOST=true&"
    return form_data
  end

  def process_each_file
    file_path = peon.copy_and_unzip_temp(file: @csv_file_name , from: SUB_FOLDER)     
    @hash_in_hash = read_csv(file_path)
    @all_files = peon.give_list(subfolder: SUB_FOLDER)

    @all_files.each do |file_name|
      puts "Parsing file #{file_name}".yellow
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
      lawyers = @parser.get_table_rows(file_content)

      lawyers.each do |lawyer|
        _ , relative_uri = @parser.get_user_id_and_name_from_row(lawyer)
        user_id = relative_uri.split("?ID=")[1]
        file_name = Digest::MD5.hexdigest(user_id)
        puts "Processing Inner link #{relative_uri}".blue
        inner_file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
        user_info, _ = @parser.get_info_from_details_page(inner_file_content)
        @hash = @parser.parse_user_details(user_info)
        name_prefix = get_name_prefix(@hash[:full_name])
        
        @hash['name_prefix'] = name_prefix if name_prefix.present?
        @hash['date_admited'] =  Date.strptime(@hash[:admisson_date], "%m/%d/%Y") if @hash[:admisson_date].present?

        @hash['registration_status'] = @hash[:current_status]
        @hash['data_source_url'] = "https://attorneyinfo.aoc.arkansas.gov/info/attorney/" + relative_uri
        
        full_name = clean_name(@hash[:full_name])
        if @hash_in_hash[full_name]
          list_of_lawyers = @hash_in_hash[full_name]
          if list_of_lawyers.length > 1
            list_of_lawyers.each do |lawyer|
              if lawyer['date_admited'].present?
                if Date.strptime(lawyer['date_admited'], '%m/%d/%Y') == @hash['date_admited']
                  lawyer.delete('date_admited')
                  @hash.merge!(lawyer)
                  # if the address_1 does't have any digits then its a law firm name else its a address
                  unless @hash['address_1'].match(/\d+/)
                    @hash['law_firm_name'] = @hash['address_1']
                  end
                  # delete the keys which are not needed address_1 and address_2
                  @hash.delete('address_1')
                  @hash.delete('address_2')
                end
              end
            end
          else
            @hash_in_hash[full_name].first.delete('date_admited')
            @hash.merge!(@hash_in_hash[full_name].first)
            # if the address_1 does't have any digits then its a law firm name else its a address
            unless @hash['address_1'].match(/\d+/)
              @hash['law_firm_name'] = @hash['address_1']
            end
            # delete the keys which are not needed address_1 and address_2
            @hash.delete('address_1')
            @hash.delete('address_2')
          end

        else
          address = @hash[:full_address]
          @hash['name'] = @hash[:full_name]
          @hash['law_firm_address'] = address
          # extract city, state and zip
          @hash['law_firm_city'] = @parser.extract_city(address)
          @hash['law_firm_state'] = @parser.extract_state(address)
          _list_of_address = address.split("\r")
          @hash['law_firm_zip'] = @parser.extract_zip(_list_of_address[-1])
        end
        
        @hash.delete(:full_name)
        @hash.delete(:full_address)
        @hash.delete(:current_status)
        @hash.delete(:admisson_date)
        @keeper.store(@hash)
      end
    end
    @keeper.delete_old_records
    @keeper.finish
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def download_details_page(file_content)
    lawyers = @parser.get_table_rows(file_content)
    lawyers.each do |lawyer|
      _ , relative_uri = @parser.get_user_id_and_name_from_row(lawyer)
      user_id = relative_uri.split("?ID=")[1]
      response, status = @scraper.get_page_with_id(user_id)
      next if status != 200
      file_name = Digest::MD5.hexdigest(user_id)
      save_file(response,file_name)
    end
  end

  def download_main_rouster_file
    response , _ = @scraper.get_request(ROUSTER_URL)
    param_hash = @parser.get_required_form_data_variables(response.body)
    @cookie = response.headers["set-cookie"]
    form_data = prepare_form_data_for_csv(param_hash)
    response , _ = @scraper.post_request(ROUSTER_URL,form_data,@cookie,false)
    save_file(response,@csv_file_name)
  end

  def prepare_form_data_for_csv(param_hash)
    client_context = CGI.escape param_hash[:client_context]
    requestVerificationToken = CGI.escape param_hash[:request_verification_token]
    page_instance_key = CGI.escape param_hash[:page_instance_key]
    view_state = CGI.escape param_hash[:view_state]
    view_genrator = CGI.escape param_hash[:view_state_gen]
    script_manager_tsm = CGI.escape param_hash[:script_manager_tsm]

    "__WPPS=s&__ClientContext=#{client_context}&__CTRLKEY=&__SHIFTKEY=&ctl01_ScriptManager1_TSM=#{script_manager_tsm}&PageInstanceKey=#{page_instance_key}&__RequestVerificationToken=#{requestVerificationToken}&TemplateUserMessagesID=ctl01_TemplateUserMessages_ctl00_Messages&PageIsDirty=false&IsControlPostBackctl01%24HeaderLogo%24HeaderLogoSpan=1&IsControlPostBackctl01%24SocialNetworking%24SocialNetworking=1&__EVENTTARGET=ctl01%24TemplateBody%24WebPartManager1%24gwpciAttorneyRoster%24ciAttorneyRoster%24ResultsGrid%24btnExportCSV&__EVENTARGUMENT=&IsControlPostBackctl01%24SearchField=1&NavMenuClientID=ctl01_TemplateMainNavigation_Primary_NavMenu&IsControlPostBackctl01%24TemplateBody%24WebPartManager1%24gwpciAttorneyRoster%24ciAttorneyRoster=1&IsControlPostBackctl01%24TemplateBody%24ContentPage1=1&IsControlPostBackctl01%24TemplateBody%24ContentPageFooter1=1&IsControlPostBackctl01%24FooterArea%24FooterContent=1&__VIEWSTATE=#{view_state}&__VIEWSTATEGENERATOR=#{view_genrator}&ctl01_TemplateMainNavigation_Primary_NavMenu_ClientState=&ctl01%24TemplateBody%24WebPartManager1%24gwpciAttorneyRoster%24ciAttorneyRoster%24ResultsGrid%24mHiddenCacheQueryId=&ctl01%24TemplateBody%24WebPartManager1%24gwpciAttorneyRoster%24ciAttorneyRoster%24ResultsGrid%24mHiddenQueryCached=False&ctl01%24TemplateBody%24WebPartManager1%24gwpciAttorneyRoster%24ciAttorneyRoster%24ResultsGrid%24Grid1%24ctl00%24ctl02%24ctl00%24GoToPageTextBox=1&ctl01_TemplateBody_WebPartManager1_gwpciAttorneyRoster_ciAttorneyRoster_ResultsGrid_Grid1_ctl00_ctl02_ctl00_GoToPageTextBox_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%221%22%2C%22valueAsString%22%3A%221%22%2C%22minValue%22%3A1%2C%22maxValue%22%3A545%2C%22lastSetTextBoxValue%22%3A%221%22%7D&ctl01%24TemplateBody%24WebPartManager1%24gwpciAttorneyRoster%24ciAttorneyRoster%24ResultsGrid%24Grid1%24ctl00%24ctl02%24ctl00%24ChangePageSizeTextBox=20&ctl01_TemplateBody_WebPartManager1_gwpciAttorneyRoster_ciAttorneyRoster_ResultsGrid_Grid1_ctl00_ctl02_ctl00_ChangePageSizeTextBox_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%2220%22%2C%22valueAsString%22%3A%2220%22%2C%22minValue%22%3A1%2C%22maxValue%22%3A10894%2C%22lastSetTextBoxValue%22%3A%2220%22%7D&ctl01%24TemplateBody%24WebPartManager1%24gwpciAttorneyRoster%24ciAttorneyRoster%24ResultsGrid%24Grid1%24ctl00%24ctl03%24ctl01%24GoToPageTextBox=1&ctl01_TemplateBody_WebPartManager1_gwpciAttorneyRoster_ciAttorneyRoster_ResultsGrid_Grid1_ctl00_ctl03_ctl01_GoToPageTextBox_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%221%22%2C%22valueAsString%22%3A%221%22%2C%22minValue%22%3A1%2C%22maxValue%22%3A545%2C%22lastSetTextBoxValue%22%3A%221%22%7D&ctl01%24TemplateBody%24WebPartManager1%24gwpciAttorneyRoster%24ciAttorneyRoster%24ResultsGrid%24Grid1%24ctl00%24ctl03%24ctl01%24ChangePageSizeTextBox=20&ctl01_TemplateBody_WebPartManager1_gwpciAttorneyRoster_ciAttorneyRoster_ResultsGrid_Grid1_ctl00_ctl03_ctl01_ChangePageSizeTextBox_ClientState=%7B%22enabled%22%3Atrue%2C%22emptyMessage%22%3A%22%22%2C%22validationText%22%3A%2220%22%2C%22valueAsString%22%3A%2220%22%2C%22minValue%22%3A1%2C%22maxValue%22%3A10894%2C%22lastSetTextBoxValue%22%3A%2220%22%7D&ctl01_TemplateBody_WebPartManager1_gwpciAttorneyRoster_ciAttorneyRoster_ResultsGrid_Grid1_ClientState=&ctl01_GenericWindow_ClientState=&ctl01_ObjectBrowser_ClientState=&ctl01_ObjectBrowserDialog_ClientState=&ctl01_WindowManager1_ClientState="
  end

  def clean_name(full_name)
    full_name.gsub!(/, Jr.|\, Jr|\,Jr\.|\,Jr/, "")
    full_name.gsub!(/, Sr.|\, Sr|\,Sr\.|\,Sr/, "")
    full_name.gsub!(/, III|\, III\.|\,III\.|\,III/, "")
    full_name.gsub!(/, II|\, II\.|\,II\.|\,II/, "")
    full_name.gsub!(/, IV|\, IV\.|\,IV\.|\,IV/, "")
    full_name.gsub!(/, V|\, V\.|\,V\.|\,V/,"")
    full_name
  end

  def get_name_prefix(full_name)
    match = [
      full_name.match(/, Jr.|\, Jr|\,Jr\.|\,Jr/),
      full_name.match(/, Sr.|\, Sr|\,Sr\.|\,Sr/),
      full_name.match(/, III|\, III\.|\,III\.|\,III/),
      full_name.match(/, II|\, II\.|\,II\.|\,II/),
      full_name.match(/, IV|\, IV\.|\,IV\.|\,IV/),
      full_name.match(/, V|\, V\.|\,V\.|\,V/)
    ]
    match.compact.first&.to_s&.gsub(/,|\./,"")&.strip
  end

  def read_csv(file_path)
    file = File.open(file_path).readlines
    @hash_in_hash = {}
    og_headers = file[0].gsub("\"", "").strip.split(",")
    # headers of csv mapped to db names
    headers = [
      "last_name",
      "first_name",
      "middle_name",
      "bar_number",
      "date_admited",
      "address_1",
      "address_2",
      "law_firm_city",
      "law_firm_state",
      "law_firm_zip"
    ]
    
    file[1..-1].each do |record|
      data = CSV.parse(record)&.first
      hash = {}
      headers.zip(data).map{|x| hash[x[0]] = x[1]}
      full_name = hash["first_name"] + " " + hash['middle_name'] + " " + hash["last_name"]
      full_name&.gsub!("  "," ")
      full_name&.strip!
      if full_name
        hash['name'] = full_name
        hash['law_firm_address'] = hash['address_1'] + " " + hash['address_2']
        unless @hash_in_hash.keys.include?(full_name)
          @hash_in_hash[full_name] = []
        end
        @hash_in_hash[full_name] << hash
      end
    end
    @hash_in_hash
  end
end
