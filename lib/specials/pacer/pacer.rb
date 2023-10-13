# frozen_string_literal: true

class Pacer
  attr_reader :agent, :page, :cookies
  
  # Michigan Eastern District Court: MIED
  # Michigan Western District Court: MIWD
  # New Jersey District Court:       NJD
  # Ohio Southern District Court:    OHSD
  # Georgia Northern District Court: GAND
  # New York Eastern District Court: NYED
  
  def initialize(username:, password:, court_id:)
    @username   = username
    @password   = password
    @target_url = "https://ecf.#{court_id}.uscourts.gov/cgi-bin/iquery.pl"
    @main_url   = 'https://pacer.login.uscourts.gov/csologin/login.jsf'
    
    login
  end
  
  def cases_links(from:, to:, &block)
    menu_text   = ['Query', 'Reports ', 'Utilities ', 'Help', 'Log Out']
    button_text = 'Run Query'
    form        = self.page.forms.first
    
    form.radiobutton_with(name: 'case_status', value: 'all').check
    form.field_with(name: 'Qry_filed_from').value = from
    form.field_with(name: 'Qry_filed_to').value   = to
    
    button = form.button_with(:value => button_text)
    cases  = self.agent.submit(form, button)
    rows   = cases.parser.css('tr').to_a.delete_if { |el| el.css('td').empty? }
    links  = cases.links.select { |link| !menu_text.include? link.text }.map { |link| [link.text, link] }.to_h
    
    rows.map! do |row|
      filed  = row.text.match(%r{\bfiled (?<filed>\d{2}/\d{2}/\d{2})}m)
      closed = row.text.match(%r{\bclosed (?<closed>\d{2}/\d{2}/\d{2})}m)
      {
        id:      row.css('a').text,
        link:    links[row.css('a').text],
        is_open: !row.text.match?(/\bclosed\b/),
        filled:  filed ? Date.strptime(filed[:filed], "%m/%d/%y") : nil,
        closed:  closed ? Date.strptime(closed[:closed], "%m/%d/%y") : nil
      }
    end
    
    if block_given?
      rows.each { |court_case| block.call(court_case) }
    else
      rows
    end
  end
  
  def docket_page(link)
    begin
    case_summary = link.click
    docket_sheet = case_summary.links.select { |link| link.text =~ /Docket Report/ }.first.click
    result = docket_sheet.forms.first.submit
    if result.forms.size == 1
      return result.forms.first.submit
    end
    result
    rescue => error
    end
  end
  
  private
  
  def login
    pf = ProxyFilter.new
    
    begin
      proxy = PaidProxy.all.to_a.shuffle.first
      
      raise "Bad proxy filtered" if pf.filter(proxy).nil?
      
      @agent = Mechanize.new
      
      @agent.user_agent_alias = "Windows Mozilla"
      @agent.set_proxy(proxy.ip, proxy.port, proxy.login, proxy.pwd)
      
      page = @agent.get("#{@main_url}?appurl=#{@target_url}")
    rescue => e
      print Time.now.strftime("%H:%M:%S ").colorize(:yellow)
      puts e.message.colorize(:light_white)
      
      pf.ban(proxy)
      
      retry
    else
      form_name            = 'loginForm'
      auth_form            = page.form_with(id: form_name)
      field_username       = auth_form.field_with(name: "#{form_name}:loginName")
      field_password       = auth_form.field_with(name: "#{form_name}:password")
      field_username.value = @username
      field_password.value = @password
      
      @page    = @agent.submit(auth_form, auth_form.buttons.first)
      @cookies = @agent.cookies.map { |coockie| { coockie.name => coockie.value } }
    end
  end
end
