require 'nokogiri'
require_relative '../models/us_epa'

class Store < Hamster::Parser

  def initialize(run_id)
    super
    @run_id = run_id
  end

  def update_history
    UsEpa.where("touched_run_id < ? AND deleted = ?", @run_id, 0).update_all(deleted: 1)
  end

  def parse(int)

    @folder = "2021_2019"
    error_file = []
    list = peon.give_list(subfolder: @folder)

    if list.size > 0
      list.each do |file|
        begin
          content = peon.give(subfolder: @folder, file: file)
          link = content.match("<link>(.*)</link>")[1]

          environmental_news = content.match?(/Environmental News/)

          html = Nokogiri::HTML(content)
          body = html.css("article.article").first
          title = body.css("h1.page-title").text
          date = body.css("p time").attr("datetime").value
          date = DateTime::strptime(date, "%Y-%m-%dT%I:%M:%SZ").strftime("%Y-%m-%d")

          contact_info = body.css("div.field div.margin-bottom-1").text

          #Environment
          #
          if environmental_news

            text_artic = body.text
            text_ar = text_artic.split("\n")
            text_clear_ar=[]
            #clear text

            text_ar.each do |item|
              text_clear = item.squish
              if text_clear.empty?
                next
              end
              text_clear_ar.push(text_clear)
            end

            ind = 0
            text_clear_ar.each_with_index do |item, index|
              if item.match? /FOR IMMEDIATE RELEASE/
                ind = index
              end
            end

            article = text_clear_ar[ind+1..-1].join("\n")
            teaser = text_clear_ar[ind+1]

            #Envitonment End
          else
            article = body.css("p span").text
            if !article.nil? and !article.empty?
              teaser = body.css("p")[2].text
              # elsif  article = body.css("p")[2..-1].empty?
              # article = body.css("div")[5..-1].text
              # teaser = body.css("div")[5].text
            else
              article = body.css("p")[2..-1].text
              teaser = body.css("p")[2].text
            end
            # res = teaser.match(/\s?(?<localtion>[A-Z]*([\s,.A-Za-z]*)?)\s?\((May|April|August|January|February|March|June|July|September|October|November|December)\s\d{1,2},\s\d{4}\)/)
          end

            res = teaser.match /^\s?(?<location>[A-Z]+([\s,.A-Za-z]+)?)|^\((?<location2>[A-Za-z,\ ]*\.),|(?<location3>[A-Z]*([\s,.A-Za-z]*)?)[\—\–\-]/
            location = res[:location] || res[:location2] || res[:location3] unless res.nil?

          #Write base
          str = article + location.to_s + date + contact_info.squish + teaser.to_s + title.squish
          md5_hash = Digest::MD5.hexdigest str
          rec = UsEpa.exists?(md5_hash: md5_hash)
          if rec
            rec = UsEpa.find_by(md5_hash: md5_hash)
            rec.touched_run_id = @run_id
            rec.deleted = 0
            rec.save
          else
            begin
            rec = UsEpa.create(run_id: @run_id, title: title,
                               teaser: teaser.to_s, article: article,
                               link: link, location: location.to_s, date: date, contact_info: contact_info,
                               data_source_url: "https://www.epa.gov/newsreleases/search/year/#{@folder}?search_api_views_fulltext=",
                               touched_run_id: @run_id, deleted: 0, md5_hash: md5_hash)
            rescue StandardError => error
              pp error
              rec = UsEpa.find_by(link: link).update(run_id: @run_id, title: title,
                                           teaser: teaser.to_s, article: article,
                                           link: link, location: location.to_s, date: date, contact_info: contact_info,
                                           data_source_url: "https://www.epa.gov/newsreleases/search/year/#{@folder}?search_api_views_fulltext=",
                                           touched_run_id: @run_id, deleted: 0, md5_hash: md5_hash)
            end
          end
            peon.move(file: file, from: @folder, to: @folder)
        rescue StandardError => err
          pp err
          error_file.push(file)
        end
      end
    end
    #   UsEpa.where("touched_run_id < ? AND deleted = ?", @run_id, 0).update_all(deleted: 1)
    if error_file.size > 0
      puts "Error Files:\n".red
      pp error_file
    end
  end

  def parse_2014_1994
    @folder = "2014_1994"
    utf8_flag = true
    error_file = []
    list = peon.give_list(subfolder: @folder)
    if list.size > 0
      list.each do |file|
        begin
          content = peon.give(subfolder: @folder, file: file)
          link = content.match("<link>(.*)</link>")[1]



          html = Nokogiri::HTML(content)
          content = content.gsub("<link>#{link}</link>", "")
          body = html.css("div.column.first").first

          article = ""
          article_arr = []
          date = ""
          contact_info = ""
          teaser = ""
          location = ""
          title = ""

          body.text.gsub(/(\r)/, "").split("\n").each do |item|

            if title.empty?
              if item.squish.size > 0
                title = item.squish
              end
              next
            end

            if date.empty?
              if item.squish.size > 0
                res_date = item.squish.match /Release\s+Date:\s+(?<date>\d{1,2}\/\d{2}\/\d{4})/
                date = res_date[:date] unless res_date.nil?

                res_con_info = item.squish.match /Contact Information: (?<contact>.*)/
                contact_info = res_con_info[:contact].squish unless res_con_info.nil?
              end
              next
            end

            if item.squish.size > 0
              article_arr.push(item.squish)
            end
          end

          teaser = article_arr[0]
          res = teaser.match(/^\(\d{1,2}\/\d{2}\/\d{2}\s{1,2}[-]\s{1,2}(?<location1>[A-Z]+([,.A-Za-z\s]+)?)\)\s+[—–−-]{1}|^\s?(?<location2>[A-Z]+([\s,.A-Za-z]+)?)|^\((?<location3>[A-Z,a-z.\s\d]+)\)/)
          location = (res[:location1] || res[:location2] || res[:location3]).squish unless res.nil?
          article = article_arr[1..-1].join("\n")
          date = DateTime::strptime(date, "%m/%d/%Y").strftime("%Y-%m-%d")

          #Write base
          str = article + location.to_s + date + contact_info + teaser.to_s + title
          md5_hash = Digest::MD5.hexdigest str
          rec = UsEpa.exists?(md5_hash: md5_hash)
          if rec
            rec = UsEpa.find_by(md5_hash: md5_hash)
            rec.touched_run_id = @run_id
            rec.deleted = 0
            rec.save
          else
            rec = UsEpa.create(run_id: @run_id, title: title,
                               teaser: teaser.to_s, article: article,
                               link: link, location: location.to_s, date: date,
                               data_source_url: "https://archive.epa.gov/epapages/newsroom_archive/newsreleases/",
                               touched_run_id: @run_id, deleted: 0, md5_hash: md5_hash)
          end
          peon.move(file: file, from: @folder, to: @folder)
        rescue StandardError => err
          puts err.to_s.red
          error_file.push({ file: file, error: err })
        end
      end
    end
    # UsEpa.where("touched_run_id < ? AND deleted = ?", @run_id, 0).update_all(deleted: 1)
    if error_file.size > 0
      puts "Error Files:\n".red
      pp error_file
    end
  end

  def parse_2019_2015
    @folder = "2019_2015"
    error_file = []
    list = peon.give_list(subfolder: @folder)
    if list.size > 0
      list.each do |file|
        begin
          content = peon.give(subfolder: @folder, file: file)
          link = content.match("<link>(.*)</link>")[1]
          res = content.scan(/codepage=\"(?<codepage>.*)\"/)

          if ! res.empty? && ! res.nil? && res[:codepage] != "utf-8"
            utf8_flag = false
          end

          html = Nokogiri::HTML(content)
          content = content.gsub("<link>#{link}</link>", "")
          body = html.css("div.node.node-news-release.node-unpublished.clearfix.view-mode-full").first
          if body.nil?
            body = html.css("section.main-content").first
          end
          article = ""
          article_arr = []
          date = ""
          contact_info = ""
          teaser = ""
          location = ""
          title = ""

          #  body.text.gsub(/(\r)/, "").split("\n").each do |item|

          title = body.css("h1.page-title").text
          date = body.css("div.field-block span.date-display-single").text
          contact_info = body.css("div.field-collection-container.clearfix").text
          article = body.css("p").text.squish

          teaser = article.split("/n")[0]
          res = teaser.match(/^\(\d{1,2}\/\d{2}\/\d{2}\s{1,2}[-]\s{1,2}(?<location1>[A-Z]+([,.A-Za-z\s]+)?)\)\s+[—–−-]{1}|^\s?(?<location2>[A-Z]+([\sA-Za-z]+)?)[—–−-]{1}|^\((?<location3>[A-Z,a-z.\s\d]+)\)/)
          location = (res[:location1] || res[:location2] || res[:location3]).squish unless res.nil?
          # article = article_arr[1..-1].join("\n")
          date = DateTime::strptime(date, "%m/%d/%Y").strftime("%Y-%m-%d")

          #Write base
          str = article + location.to_s + date + contact_info + teaser.to_s + title
          md5_hash = Digest::MD5.hexdigest str
          rec = UsEpa.exists?(md5_hash: md5_hash)
          if rec
            rec = UsEpa.find_by(md5_hash: md5_hash)
            rec.touched_run_id = @run_id
            rec.deleted = 0
            rec.save
          else
            rec = UsEpa.create(run_id: @run_id, title: title,
                               teaser: teaser.to_s, article: article,
                               link: link, location: location.to_s, date: date,
                               data_source_url: "https://archive.epa.gov/epapages/newsroom_archive/newsreleases/",
                               touched_run_id: @run_id, deleted: 0, md5_hash: md5_hash)
          end
          peon.move(file: file, from: @folder, to: @folder)
        rescue StandardError => err
          puts err.to_s.red
          error_file.push({ file: file, error: err })
        end
      end
    end
    # UsEpa.where("touched_run_id < ? AND deleted = ?", @run_id, 0).update_all(deleted: 1)
    if error_file.size > 0
      puts "Error Files:\n".red
      pp error_file
    end
  end
end
