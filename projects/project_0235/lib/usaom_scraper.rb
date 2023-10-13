# frozen_string_literal: true

require_relative '../models/us_dept_usao'
require_relative '../models/us_dept_usao_tags'
require_relative '../models/us_dept_usao_tag_article_links'

class USAOMScraper <  Hamster::Scraper
  DOMAIN = "https://www.justice.gov"
  MAIN_PAGE = "https://www.justice.gov/usao/pressreleases?keys=&items_per_page=50"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = USAOM.pluck(:link)
    @inserted_tags = USAOMTags.pluck(:tag)
    @data_array = []
  end

  def main
    page_no = 0
    page_suffix = ""
    while true
      unless page_no == 0
        page_suffix = "&page=" + page_no.to_s
      end
      document = connect_to(MAIN_PAGE + page_suffix)
      links = document.css(".view-content a").map{|e| DOMAIN + e["href"]}
      links.each do |link|
        next if @already_processed.include? link
        document = connect_to(link)
        link_parser(document, link)
      end
      USAOM.insert_all(@data_array) if !@data_array.empty?
      break if page_no == 20

      @data_array = []
      page_no += 1
    end
  end

  private

  def fetch_data(document)
    subtitle      = document.css(".node-subtitle", "#node-subtitle").first.text.strip rescue nil
    date          = document.css(".date-display-single").first["content"].split("T").first rescue nil
    bureau_office = document.css(".field.field--name-field-pr-component a").first.text.strip rescue nil
    contact_info  = document.css(".field.field--name-field-pr-contact").first.to_s
    release_no    = document.css(".field.field--name-field-pr-number .field__items").first.text.strip rescue nil
    tags          = document.css(".field.field--name-field-pr-topic .field__items div").map{|e| e.text.strip}
    state         = fetch_state(bureau_office)
    [date, bureau_office, contact_info, release_no, tags, state, subtitle]
  end

  def fetch_data_for_changed_formate(document)
    title         = document.css("h1.page-title").first.text.strip rescue nil
    date          = document.css("time")[0].text.to_date rescue nil?
    bureau_office = document.css("div.field__items").last.text.squish rescue nil
    contact_info  = document.css("div.field_contact").first.to_s
    release_no    = document.css("div.field__items").last.text.squish
    tags          = document.css("div.field__items").first.css("div").map{|e| e.text.strip}
    state         = fetch_state(bureau_office)
    [title, date, bureau_office, contact_info, release_no, tags, state, nil]
  end

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def fetch_state(value)
    (value.include? "-") ? value.split("-").last.strip : nil
  end

  def link_parser(document, link)
    title = document.css(".node-title", "#node-title").first.text.strip rescue nil
    date, bureau_office, contact_info, release_no, tags, state, subtitle = fetch_data(document) unless title.nil?
    title, date, bureau_office, contact_info, release_no, tags, state, subtitle = fetch_data_for_changed_formate(document) if title.nil?
    contact_info = contact_info == "" ? nil : contact_info
    unless tags.empty?
      tags_table_insertion(tags,link[-1])
    end
    article = fetch_article(document)
    with_table = article.css("table").empty? ? 0 : 1
    teaser = fetch_teaser(article)
    (teaser.nil? || teaser.empty?) ? dirty_news = 1 : dirty_news = 0
    data_hash = {
      title: title,
      teaser: teaser,
      subtitle: subtitle,
      contact_info: contact_info,
      release_no: release_no,
      article: article.to_s,
      link: link[-1],
      data_source_url: "https://www.justice.gov/usao/pressreleases",
      date: date,
      bureau_office: bureau_office,
      state: state,
      with_table: with_table,
      dirty_news: dirty_news,
    }
    USAOM.insert(data_hash) unless data_hash.nil?
    @data_array.push(data_hash)
  end

  def tags_table_insertion(tags,link)
    tags.each do |tag|
      unless @inserted_tags.include? tag
        USAOMTags.insert(tag: tag)
        @inserted_tags.push(tag)
      end
      id = USAOMTags.where(:tag => tag).pluck(:id)
      USAOMTALinks.insert(tag_id: id[0], article_link: link)
    end
  end

  def fetch_article(document)
    article = document.css("div.field--name-field-pr-body div.field__items") rescue nil
    article = document.css('div.node-body') if article.nil? or article.empty?
    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article.css("script").remove
    article
  end

  def fetch_teaser(article)
    teaser = nil
    article.css("*").each do |node|
      next if node.text.squish == ""
      if (node.text.squish[-10..].include? "." or node.text.squish[-10..].include? ":") and node.text.squish.length > 50
        teaser = node.text.squish
        break

      end
    end
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == ""

        if (teaser[-2..].include? "." or teaser[-2..].include? ":") and teaser.length > 100
          break

        end
      end
    end
    teaser = dot_handling(teaser)
    
    if teaser.length  < 20
      return nil
    end
    if teaser[-1].include? ":"
      teaser[-1] = "..."
    end
    cleaning_teaser(teaser)
  end

  def dot_handling(teaser)
    if teaser.length > 600
      outer_teaser = teaser
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      if dot.count <= 3 and teaser[0..(teaser.index dot[-1])].join(" ").size < 100
        teaser = teaser.join(" ")
      elsif dot.count == 1 and dot.first.size == 2
        teaser = teaser.join(" ")[0..590]+":"
      else
        all_indexes = []
        teaser.each_with_index{|e, index| all_indexes << index if e.include? '.'}
        counter = all_indexes.size
        while true
          break if counter == 0
          if teaser[0..all_indexes[-1]].join(" ").size > 600
            counter -=1
            all_indexes.pop
          else
            teaser = teaser[0..all_indexes[-1]].join(" ")
            break
          end
        end
        if teaser[-3..-1].include? ' ' and teaser[-3..-1].include? '.' and teaser[-3..-1].scan(/\w/).count == 1
          teaser = outer_teaser[0..590].split.join(" ")+":"
        end
      end
    end
    teaser
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–' , 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('‒' , 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-' , 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
        teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
  end

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
    # end
  end
end
