# frozen_string_literal: true

class Scraper < Connect
  attr_writer :type, :year
  
  def initialize(args)
    super
    @args = args
    @base_link = "https://fcdcfcjs.co.franklin.oh.us"
    @page_search = "https://fcdcfcjs.co.franklin.oh.us/CaseInformationOnline/caseSearch"
    @debug = true if args[:debug]
    if args[:download] || args[:auto] || args[:update]
      @recs = 25
      @check = 0
      @count = 0
      @name = ""
      @fname = ""
      @sel_type = ""
      connect(url: "https://fcdcfcjs.co.franklin.oh.us/CaseInformationOnline/")
      accept
    elsif args[:update_description]
      @page_search = "https://fcdcfcjs.co.franklin.oh.us/CaseInformationOnline/nameSearch" 
      @recs = 350
      @case_years = ""
      @sel_type = ""
      @fname = ""
      connect(url: "https://fcdcfcjs.co.franklin.oh.us/CaseInformationOnline/")
      accept
    end
  end

  def accept?
    @content_html.css("form input[name=Accept]").size > 0
  end

  def accept
    return unless accept?
    url     = @content_html.css("form @action").first.value
    inputs  = @content_html.css("form input").map {|item| "#{item.attr(:name)}=#{item.attr(:value)}" }.join("&")
    connect(url: @base_link + url, method: :post, req_body: inputs)
    @current_link = @base_link + url
  end

  def search(forward)
    unless forward.nil?
      @forward = forward
      @case_years = forward[0]
      @case_type = forward[1]
      @case_number = forward[2]
      puts ("Forward:#{@forward}").green if @debug
      @logger.info("Forward:#{@forward}")
    else
      @case_years = @forward[0]
      @case_number = @forward[2].to_i + 1
      @forward[2] = @case_number 
      @count +=1
      puts ("Forward nil:#{@forward}").yellow if @debug
      @logger.info("Forward nil:#{@forward}")
      puts ("Count:#{@count}").yellow if @debug
      @logger.info("Count:#{@count}")
    end

    if @forward[1].to_s != @type.to_s
      puts ("Next type").red if @debug
      @logger.info("Next type")
      return [nil, nil]
    elsif @forward[0].to_i != @year.to_i
      puts ("Next year").red if @debug
      @logger.info("Next year")
      return [nil, nil]
    end

    send_request("","","")

    if @count == 100
      puts ("Empty record: #{@count}").red if @debug
      @logger.info("Empty record: #{@count}")
      @count = 0
      puts @forward if @debug
      @logger.info(@forward)
      return [nil, nil]
    end

    check_last_year
    save_page
  end

  def check_last_year
    time = (Time.now).strftime("%Y").split('').last(2).join.to_i + 1
    if @forward[0].to_i >= time
      return @check = nil
    end
  end

  def save_page
    content_raw_html = @raw_content.body
    if @check == nil
      @check = 0
      puts ("Last case").red if @debug
      @logger.info("Last case")
      return [nil, nil]
    elsif @content_html.css("font[color=red]").text.include?("NO CASE MATCHED THE SEARCH CRITERIA") || @content_html.css("font[color=red]").text.include?("NO CASE(S) MATCHED THE SEARCH")
      puts ("NO CASE MATCHED THE SEARCH CRITERIA").red if @debug
      @logger.info("NO CASE MATCHED THE SEARCH CRITERIA")
      return [content_raw_html, nil]
    elsif content_raw_html.size < 500
      puts ("#{content_raw_html.to_s}").red if @debug
      @logger.info("#{content_raw_html.to_s}")
      sleep 300
      forward = @forward
      search(forward)
    elsif content_raw_html.size < 20000 && !@content_html.css("font[color=red]").text.include?("NO CASE MATCHED THE SEARCH CRITERIA")
      puts ("Case present but page not load").red if @debug
      @logger.info("Case present but page not load")
      puts content_raw_html.size  if @debug
      @logger.info(content_raw_html.size)
      forward = @forward
      search(forward)
    else
      @count = 0
      file_name = @content_html.css("link[rel=alternate]").attr("href").text.split('/').last
      peon.put(file: "case_#{file_name}.html", content: content_raw_html) rescue nil
      [content_raw_html, "case_#{file_name}.html"]
    end
  end
  
  def send_request(name, date, case_type)
    if @args[:update_description]
      @txt_calendar = date
      @case_type = case_type
      if @case_type == "AP"
        @sel_type = "Appeals"
      elsif @case_type == "DR"
        @case_type = "AP"
      elsif  @case_type == "EX" || @case_type == "MS" || @case_type == "JG" || @case_type == "LP" || @case_type == "CV"
        @case_type = "AP"
      end

      if name.class == Array 
        @name = name.last
        @fname = name.first
      elsif name.class == String && name.split.size < 3
        @name = name.split.last
        @fname = name.split.first
      else
        @name = name
        @fname = ""
      end 
    end

  query_request = {
      "attyIdx"=>"",
      "advFlag"=>"show",
      "reallySubmit"=>"true",
      "lname"=>@name,
      "fname"=>@fname,
      "mint"=>"",
      "selType"=>@sel_type,
      "caseYear"=>@case_years,
      "caseYear_h"=>"",
      "caseType"=>@case_type,
      "caseType_h"=>"",
      "caseSeq"=>@case_number.to_s,
      "caseSeq_h"=>"",
      "personType"=>"P",
      "attyNum"=>"",
      "txtCalendar1"=>@txt_calendar,
      "txtCalendar2"=>@txt_calendar,
      "recs"=>@recs
    }

    req_body = query_request.map {|key, value| "#{key}=#{value}" }.join("&")
    connect(url: @page_search, method: :post, req_body: req_body)
  end

  def store_to_aws(link)
    s3 = AwsS3.new(bucket_key = :us_court, account=:us_court)
    cobble = Dasher.new(:using=>:cobble)
    body = cobble.get(link[1].to_s)
    key = "#{link[0].split.join('_')}_#{Digest::MD5.new.hexdigest(link[1])}" + '.pdf'
    s3.put_file(body, key, metadata = {url: link[1]})
  end
end
