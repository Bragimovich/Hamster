# frozen_string_literal: true

class Scraper < Connect
  attr_writer :javax_faces, :letter
  def initialize(options)
    super
    unless options[:store_img]
      @proxies = PaidProxy.where(is_socks5: 1).where(locked_to_scrape07: 0).to_a
      agent = FakeAgent.new
      @user_agent = agent.any
      @row_count = 0
    end
  end

  def swap_proxy
    @proxy = @proxies.sample
  end

  def main_page
    connect(url: "https://offender.fdle.state.fl.us/offender/sops/offenderSearch.jsf", proxy: @proxy, user_agent: @user_agent)
    @javax_faces = @content_html.css("[id='j_id1:javax.faces.ViewState:0']").attr("value").text
    @content_html.css("ul[id='offenderSearchForm:countyResi_items']").css('li').map {|el| el.text}
  end
  
  def search_page
    query_request = {
      'javax.faces.partial.ajax' => 'true',
      'javax.faces.source' => 'offenderSearchForm:offenderSearchBtn',
      'javax.faces.partial.execute' => 'offenderSearchForm',
      'javax.faces.partial.render' => 'offenderSearchForm',
      'offenderSearchForm:offenderSearchBtn' => 'offenderSearchForm:offenderSearchBtn',
      'button' => 'search',
      'offenderSearchForm' => 'offenderSearchForm',
      'offenderSearchForm:firstName' =>  @letter.first,
      'offenderSearchForm:lastName' => @letter.last,
      'offenderSearchForm:offenderType_input' => '3',
      'offenderSearchForm:offenderStatus' => '1',
      'offenderSearchForm:offenderStatus' => '6',
      'offenderSearchForm:offenderStatus' => '7',
      'offenderSearchForm:offenderStatus' => '8',
      'offenderSearchForm:offenderStatus' => '9',
      'offenderSearchForm:stateStatus_focus' => '' ,
      'offenderSearchForm:stateStatus_input' => '1',
      'offenderSearchForm:imagOption_input' => 'on',
      'offenderSearchForm:aliasOption_input' => 'on',
      'offenderSearchForm:adbvancedOptionsPanel_collapsed' => 'false',
      'offenderSearchForm:searchPanel_collapsed' => 'false',
      'offenderSearchForm:resultReturnType_focus' => '' ,
      'offenderSearchForm:resultReturnType_input' => '1',
      'offenderSearchForm:searchOffenderResultTableId_rppDD' => '10',
      'offenderSearchForm:searchOffenderResultTableId_selection' => '' ,
      'javax.faces.ViewState' => @javax_faces
    }

    req_body = query_request.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    res = connect(url: "https://offender.fdle.state.fl.us/offender/sops/offenderSearch.jsf", method: :post, req_body: req_body, proxy: @proxy, user_agent: @user_agent)
    all_record = @content_html.css("span[class='ui-paginator-current']").text
    all_record.empty? ? nil : all_record.split(',')[1].split(' ').last
  end

  def next_page
    req_body = {
      'javax.faces.partial.ajax' => 'true',
      'javax.faces.source' => 'offenderSearchForm:searchOffenderResultTableId',
      'javax.faces.partial.execute' => 'offenderSearchForm:searchOffenderResultTableId',
      'javax.faces.partial.render' => 'offenderSearchForm:searchOffenderResultTableId',
      'javax.faces.behavior.event' => 'page',
      'javax.faces.partial.event' => 'page',
      'offenderSearchForm:searchOffenderResultTableId_pagination' => 'true',
      'offenderSearchForm:searchOffenderResultTableId_first' => @row_count.to_s,
      'offenderSearchForm:searchOffenderResultTableId_rows' => '25',
      'offenderSearchForm:searchOffenderResultTableId_skipChildren' => 'true',
      'offenderSearchForm:searchOffenderResultTableId_encodeFeature' => 'true',
      'offenderSearchForm:firstName' =>  @letter.first,
      'offenderSearchForm:lastName' => @letter.last,
      'offenderSearchForm:offenderType_input' => '3',
      'offenderSearchForm:offenderStatus' => '1',
      'offenderSearchForm:offenderStatus' => '6',
      'offenderSearchForm:offenderStatus' => '7',
      'offenderSearchForm:offenderStatus' => '8',
      'offenderSearchForm:offenderStatus' => '9',
      'offenderSearchForm:stateStatus_focus' => '' ,
      'offenderSearchForm:stateStatus_input' => '1',
      'offenderSearchForm:imagOption_input' => 'on',
      'offenderSearchForm:aliasOption_input' => 'on',
      'offenderSearchForm:adbvancedOptionsPanel_collapsed' => 'false',
      'offenderSearchForm:searchPanel_collapsed' => 'true',
      'offenderSearchForm:resultReturnType_focus' => '' ,
      'offenderSearchForm:resultReturnType_input' => '1',
      'offenderSearchForm:searchOffenderResultTableId_rppDD' => '25',
      'offenderSearchForm:searchOffenderResultTableId_rppDD' => '25',
      'offenderSearchForm:searchOffenderResultTableId_selection' => '' ,
      'javax.faces.ViewState' => @javax_faces      

    }

    req_param = req_body.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    res = connect(url: "https://offender.fdle.state.fl.us/offender/sops/offenderSearch.jsf", method: :post, req_body: req_param, proxy: @proxy, user_agent: @user_agent)
    @row_count +=25
    res.body
  end

  def view_offender_page(row)
    req_body = {
      'javax.faces.partial.ajax' => 'true',
      'javax.faces.source' => row,
      'javax.faces.partial.execute' => '@all',
      'javax.faces.partial.render' => 'sopsFlyer',
      row => row,
      'offenderSearchForm' => 'offenderSearchForm',
      'offenderSearchForm:firstName' =>  @letter.first,
      'offenderSearchForm:lastName' => @letter.last,
      'offenderSearchForm:offenderType_input' => '3',
      'offenderSearchForm:offenderStatus' => '9',
      'offenderSearchForm:stateStatus_focus' => '' ,
      'offenderSearchForm:stateStatus_input' => '1',
      'offenderSearchForm:imagOption_input' => 'on',
      'offenderSearchForm:aliasOption_input' => 'on',
      'offenderSearchForm:adbvancedOptionsPanel_collapsed' => 'false',
      'offenderSearchForm:searchPanel_collapsed' => 'true',
      'offenderSearchForm:resultReturnType_focus' => '' ,
      'offenderSearchForm:resultReturnType_input' => '1',
      'offenderSearchForm:searchOffenderResultTableId_rppDD' => '10',
      'offenderSearchForm:searchOffenderResultTableId_rppDD' => '10',
      'offenderSearchForm:searchOffenderResultTableId_selection' => '' ,
      'javax.faces.ViewState' => @javax_faces  
    }
    
    req_param = req_body.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    connect(url: "https://offender.fdle.state.fl.us/offender/sops/offenderSearch.jsf", method: :post, req_body: req_param, proxy: @proxy, user_agent: @user_agent)
  end

  def store_to_aws(link)
    @aws_s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)
    cobble = Dasher.new(:using=>:cobble)
    body = cobble.get(link)
    key = Digest::MD5.new.hexdigest(link)
    mugshot_link = @aws_s3.put_file(body, "sex_offenders_mugshots/FL/#{key}.jpg")
  end
end
