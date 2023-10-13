class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def post(url ,param_hash ,cookie)
    form_data  = _prepare_form_data(param_hash)
    headers = {
      "Cookie": set_cookie(cookie),
      "Connection": "keep-alive",
      "Host": "mobar.org",
      "Origin": "https://mobar.org",
      "Referer": "https://mobar.org/site/content/For-the-Public/Lawyer_Directory.aspx",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "Pragma": "no-cache",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "Linux",
      "Sec-Fetch-Dest": "empty",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Site": "same-origin",
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36 OPR/90.0.4480.84",
      "X-MicrosoftAjax": "Delta=true",
      "X-Requested-With": "XMLHttpRequest"
    }
    retries = 0
    begin
      puts "Processing URL (POST REQUEST) -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter, method: :post, headers: headers, req_body: form_data)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end
  
  private

  def set_cookie(raw_cookie)
    list = ['ASP.NET_SessionId','__RequestVerificationToken']
    cookies_list = []
    raw_cookie.split(";").each do |i|
      list.each do |l|
        if i.include?(l)
          cookies_list << i
        end
      end
    end
    _cookie = ""
    cookies_list.each do |cookie|
      cookie = cookie.gsub(' SameSite=Lax,','')
      cookie = cookie.gsub(' HttpOnly,','')
      _cookie += cookie
      _cookie += ";"
    end
    # _cookie += ' Asi.Web.Browser.CookiesEnabled=true'
    _cookie
  end

  def reporting_request(response)
    if response.present?
      puts '=================================='.yellow
      print 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      puts response.status == 200 ? status.greenish : status.red
      puts '=================================='.yellow
    end
  end

  def _prepare_form_data(param_hash)
    manager = CGI.escape param_hash[:manager]
    client_context = CGI.escape param_hash[:client_context]
    requestVerificationToken = CGI.escape param_hash[:request_verification_token]
    page_instance_key = CGI.escape param_hash[:page_instance_key]
    view_state = CGI.escape param_hash[:view_state]
    view_genrator = CGI.escape param_hash[:view_state_gen]
    script_manager_tsm = CGI.escape param_hash[:script_manager_tsm]
    city = param_hash[:city] || ""
    last_name = param_hash[:last_name] || ""

    form_data = ""
    form_data += "ctl01$ScriptManager1=ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ListerPanel|#{manager}&"
    form_data += "__WPPS=s&"
    form_data += "__ClientContext=#{client_context}&"
    form_data += "__CTRLKEY=&"
    form_data += "__SHIFTKEY=&"
    form_data += "ctl01_ScriptManager1_TSM=#{script_manager_tsm}&"
    form_data += "PageInstanceKey=#{page_instance_key}&"
    form_data += "__RequestVerificationToken=#{requestVerificationToken}&"
    form_data += "TemplateUserMessagesID=ctl01_TemplateUserMessages_ctl00_Messages&"

    form_data += "PageIsDirty=false&"
    form_data += "IsControlPostBackctl01$HeaderLogo$HeaderLogoSpan=1&"
    form_data += "IsControlPostBackctl01$SocialNetworking$SocialNetworking=1&"
    form_data += "IsControlPostBackctl01$SearchField=1&"
 
    form_data += "__EVENTTARGET=#{manager}&"
    form_data += "__EVENTARGUMENT=&"

    form_data += "NavMenuClientID=ctl01_Primary_NavMenu&"
    form_data += "IsControlPostBackctl01$TemplateBody$WebPartManager1$gwpciNewContentHtml_8e1275428a75426b85a00d2df206b09b$ciNewContentHtml_8e1275428a75426b85a00d2df206b09b=1&"

    form_data += "IsControlPostBackctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage1=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage2=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage3=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage4=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage5=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage6=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage7=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage8=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage9=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage10=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage11=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage12=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage13=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage14=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage15=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage16=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage17=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage18=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage19=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage20=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage21=1&"
    form_data += "IsControlPostBackctl01$TemplateBody$ContentPage22=1&"
    form_data += "IsControlPostBackctl01$FtContact$FooterCommunications=1&"
    form_data += "IsControlPostBackctl01$FtSocialNetworking$SocialNetworking=1&"
    form_data += "IsControlPostBackctl01$FtCopyright$FooterCopyright=1&"
    form_data += "IsControlPostBackctl01$FtCopyright$GAtrackerscript=1&"

    form_data += "__VIEWSTATE=#{view_state}&"
    form_data += "__VIEWSTATEGENERATOR=#{view_genrator}&"
    form_data += "ctl01$lastClickedElementId=id|ctl01_TemplateBody_WebPartManager1_gwpciLawyerDirectory_ciLawyerDirectory_ResultsGrid_Sheet0_Input0_TextBox1&"

    form_data += "ctl01$SearchField$SearchTerms=Keyword%20Search&"
    form_data += "ctl01_Primary_NavMenu_ClientState=&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$mHiddenCacheQueryId=&"

    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$mHiddenQueryCached=False&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$ctl01=2762b63b-d10c-471d-a596-4b3011c614cc.FS1.FL4&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$Input0$TextBox1=#{last_name}&"

    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$ctl04=2762b63b-d10c-471d-a596-4b3011c614cc.FS1.FL5&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$Input1$TextBox1=&"

    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$ctl07=2762b63b-d10c-471d-a596-4b3011c614cc.FS1.FL6&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$Input2$TextBox1=#{city}&"

    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$ctl10=2762b63b-d10c-471d-a596-4b3011c614cc.FS1.FL7&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$Input3$TextBox1=&"

    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$ctl13=2762b63b-d10c-471d-a596-4b3011c614cc.FS1.FL8&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$Input4$TextBox1=&"

    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$ctl16=2762b63b-d10c-471d-a596-4b3011c614cc.FS1.FL19&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$Input5$TextBox1=&"
    form_data += "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$HiddenKeyField1=code_id&"

    form_data += "ctl01_GenericWindow_ClientState=&"
    form_data += "ctl01_ObjectBrowser_ClientState=&"
    form_data += "ctl01_ObjectBrowserDialog_ClientState=&"
    form_data += "ctl01_WindowManager1_ClientState=&"

    form_data += "__ASYNCPOST=true&"
    return form_data
  end


end