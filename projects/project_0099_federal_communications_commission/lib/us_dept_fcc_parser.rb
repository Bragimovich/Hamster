# frozen_string_literal: true
require_relative '../models/us_dept_fcc_categories'
require_relative '../models/us_dept_fcc_categories_article_links'
require_relative '../models/us_dept_fcc'

class UsDeptFccParser <  Hamster::Scraper

  def initialize
    super
    @all_categories = UsDeptFccCategories.select(:id, :category)
    @all_links = UsDeptFcc.pluck(:link)
  end

  def parser
    records = get_records
    return if records.empty?
    year = Date.today.year
    path = "#{storehouse}store/#{year}"
    year_files = Dir["#{path}/*.txt"]
    year_files.each do |file_name|
      file = (file_name.include? path)? file_name.split('/').last : file_name
      record = records.select{ |e| e[:file_name] == file }[0] rescue nil
      next if record.nil?
      file_data = (file_name.include? path) ? File.read(file_name) : File.read("#{path}/#{file_name}")
      all_data = file_data.scan(/(.+?\n\n|.+?$)/)
      teaser = fetch_teaser(all_data)
      article = fetch_article(all_data)
      article = cleaning_teaser(article)
      record[:teaser] = teaser
      record[:article] = article
      UsDeptFcc.insert(record)
    end   
  end

  def fetch_article(all_data)
    start_ind = 0
    end_ind = -1
    all_data.each_with_index do |data , ind|
      next if data[0].squish.gsub("﻿" , "") == "" or data[0].squish.length == 1
      if (data[0].squish[-2..-1].include? "." or data[0].squish[-2..-1].include? ":") and data[0].squish.length > 100
        start_ind = all_data.index data
        break
      end
    end
    all_data.each_with_index do |data , ind|
      next if data[0].squish.gsub("﻿" , "") == "" or data[0].squish.length == 1
      if data[0].squish == "###"
        end_ind = all_data.index data
        break  
      end
    end
    start_ind = 0 if start_ind > end_ind  
    article = all_data[start_ind..end_ind - 1].join(" ")
  end

  def fetch_teaser(all_data)
    teaser = nil
    all_data.each_with_index do |data , ind|
      next if data[0].squish.gsub("﻿" , "") == "" or data[0].squish.length == 1
      if (data[0].squish[-2..-1].include? "." or data[0].squish[-2..-1].include? ":") and data[0].squish.length > 100
        teaser = data[0].squish
        break 
      end
    end
    if teaser == '-' or teaser.nil? or teaser == ""
      all_data.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == ""
        if (teaser[-2..].include? "." or teaser[-2..].include? ":") and teaser.length > 100
          break
        end
      end
    end
    if !teaser.nil? 
      if teaser.length > 600
        teaser = teaser[0..600].split
        dot = teaser.select{|e| e.include? "."}
        dot = dot.uniq
        ind = teaser.index dot[-1]
        teaser = teaser[0..ind].join(" ")
      elsif teaser[-2..-1].include?(":") and !teaser.nil?
        teaser[-1] = "..."
      end
    end
    teaser = cleaning_teaser(teaser)
  end

  def get_records
    data_array = []
    dataset = UsDeptFccCategoriesArticleLinks
    files = peon.list(subfolder: "#{Date.today.year}/html") rescue []
    files.each do |file|
      file =  peon.give(file:file, subfolder: "#{Date.today.year}/html")
      inner_page =  Nokogiri::HTML(file)
      link = inner_page.css('head link')[1]['href']
      next if @all_links.include? link
      categories_div = inner_page.css("div#content ul.edocs li").select{|e| e.css("strong").text.include? "Bureau"}
      if categories_div.count > 0
        category_array = categories_div[0].text.split('Bureau(s):').last.squish.split(',')
        category_array.each do |category|
          category_id = @all_categories.select{|k| k[:category] == category.strip}.first[:id] rescue "-"
          next if category_id == "-"
          data_hash = {
            article_link: link,
            category_id: category_id,
            data_source_url: 'https://www.fcc.gov/news-events/headlines?field_released_date_value%5Bvalue%5D%5Byear%5D=2023&items_per_page=25'
          }
          data_hash = dataset.flail{|k| [k, data_hash[k]] }
          dataset.store(data_hash)
        end
      end
      full_title = inner_page.css('.edoc__full-title .field__item').text
      contact_info = inner_page.css('.edoc__omr-contact').to_s
      contact_info = nil if contact_info.empty?
      date = inner_page.css('.edoc__release-dt div')[1].text.squish.to_date rescue nil
      file_link = inner_page.css('a.document-link').map { |e| e['href'] }
      file_link = file_link.select { |e| e.include? '.txt'}[0] rescue nil
      file_name = file_link.split('/').last if file_name.nil?
      data = {
        title: full_title,
        link: link,
        contact_info: contact_info.to_s,
        file_link: file_link,
        file_name: file_name,
        date: date
      }
      data_array << data
    end
    data_array
  end

  def fetch_date(data)
    date = data.css("li").select{|e| e.text.include? "Released On:"}[0]
    Date.parse(date.text.split(":").last) rescue nil
  end
  
  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–' , 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--' , 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
        teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
  end
end
