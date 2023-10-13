require 'nokogiri'
require_relative '../models/us_dhs'

class Store < Hamster::Parser

  def initialize(run_id)
    super
    @run_id = run_id
  end

  def update_history
    UsDhs.where("touched_run_id < ? AND deleted = ?", @run_id, 0).update_all(deleted: 1)
  end

  def parse
    @folder = "current"
    error_file = []
    list = peon.give_list(subfolder: @folder)
    if list.size > 0
      list.each do |file|
        begin
          content = peon.give(subfolder: @folder, file: file)
          link = content.match("<link>(.*)</link>")[1]
          environmental_news = content.match?(/Environmental News/)
          html = Nokogiri::HTML(content)
          body = html.css("main div.region-content>div.region-content")
          # body = html.css("article.node-press-release").first
          body.css("div.sidebar").remove
          header = body.search("h1.uswds-page-title.page-title")
          title = header.text.squish


          if html.css("h1").text.match?(/^Access Denied$/)
            peon.move(file: file, from: @folder, to: "accessdenied")
            break
          end

          if title.downcase.include?("page not found")
            peon.move(file: file, from: @folder, to: "notfound")
            break
          end

          if title.empty?
            peon.move(file: file, from: @folder, to: "title_empty")
            break
          end

          release_date = body.search("span.news-release-date-label").first.parent
          date = release_date.text.squish.match /Release Date:\s(?<date>.*)/
          date = DateTime::strptime(date[:date], "%B %d, %Y").strftime("%Y-%m-%d")
          body = body.css("div#block-mainpagecontent>article>div").first.css(">div").first
          # body.css("p[style=\"text-align:center\"]").remove
          # body_ar = body.children
          # body = body_ar.map { |item| item.to_s.squish }
          teaser = html.css("meta[property=\"og:description\"]")
          teaser = teaser.attr("content").value unless teaser.nil? or teaser.empty?
          contact_info = ""
          article = body.to_s
          res = body.text.squish.match /^\s?(?<location>[A-Z]{3,10}([\s,.A-Za-z]{0,5})?)[\—\–\-]|^\((?<location2>[A-Za-z,\ ]{5,10}\.),|^(?<location3>[A-Z][a-z]{3,10}([\s,.A-Za-z]{0,5}.)?)\s[\—\–\-]/
          location = res[:location] || res[:location2] || res[:location3] unless res.nil?
          location = (location.to_s.squish.empty?)? "" : location.to_s.squish

          #Write base
          str = article + location + date + teaser.to_s + title.squish
          md5_hash = Digest::MD5.hexdigest str
          rec = UsDhs.exists?(md5_hash: md5_hash)
          if rec
            rec = UsDhs.find_by(md5_hash: md5_hash)
            rec.touched_run_id = @run_id
            rec.deleted = 0
            rec.save
          else
            begin
            rec = UsDhs.create(run_id: @run_id, title: title,
                               teaser: teaser.to_s, article: article,
                               link: link, location: location, date: date, contact_info: contact_info,
                               data_source_url: "https://www.epa.gov/newsreleases/search/year/#{@folder}?search_api_views_fulltext=",
                               touched_run_id: @run_id, deleted: 0, md5_hash: md5_hash)
            rescue StandardError => error
              pp error
              rec = UsDhs.find_by(link: link).update(run_id: @run_id, title: title,
                                           teaser: teaser.to_s, article: article,
                                           link: link, location: location, date: date, contact_info: contact_info,
                                           data_source_url: "https://www.epa.gov/newsreleases/search/year/#{@folder}?search_api_views_fulltext=",
                                           touched_run_id: @run_id, deleted: 0, md5_hash: md5_hash)
            end
          end
            peon.move(file: file, from: @folder, to: "finished")
        rescue StandardError => err
          pp err
          error_file.push(file)
          peon.move(file: file, from: @folder, to: "error")
        end
      end
    end
    if error_file.size > 0
      puts "Error Files:\n".red
      pp error_file
    end
  end

  def parse_old

    @folder = "archive"
    error_file = []
    list = peon.give_list(subfolder: @folder)
    if list.size > 0
      list.each do |file|
        begin
          content = peon.give(subfolder: @folder, file: file)
          link = content.match("<link>(.*)</link>")[1]
          # environmental_news = content.match?(/Environmental News/)
          html = Nokogiri::HTML(content)
          body = html.css("article.node-press-release").first
          body.css("div.sidebar").remove
          header = body.search("header").remove
          title = header.text.squish
          release_date = body.search("div.field-name-field-release-date").remove
          date = release_date.text.squish.match /Release Date:\s(?<date>.*)/
          date = DateTime::strptime(date[:date], "%B %d, %Y").strftime("%Y-%m-%d")
          body_ar = body.css("div.field-item.even").children
          body = body_ar.map { |item| item.to_s.squish }
          teaser = html.css("meta[property=\"og:description\"]")
          teaser = teaser.attr("content").value unless teaser.nil?
          contact_info = ""
          article = body.join
          res = body_ar.text.squish.match /^\s?(?<location>[A-Z]{3,10}([\s,.A-Za-z]{0,5})?)[\—\–\-]|^\((?<location2>[A-Za-z,\ ]{5,10}\.),|^(?<location3>[A-Z][a-z]{3,10}([\s,.A-Za-z]{0,5}.)?)\s[\—\–\-]/
          location = res[:location] || res[:location2] || res[:location3] unless res.nil?
          location = ( location.to_s.squish.empty? ) ? "" : location.to_s.squish
          # pp location
          # pp res
          # pp body_ar.text.squish[0..25]
          # next
          #Write base
          str = article + location + date + teaser.to_s + title.squish + contact_info
          md5_hash = Digest::MD5.hexdigest str
          rec = UsDhs.exists?(md5_hash: md5_hash)
          if rec
            rec = UsDhs.find_by(md5_hash: md5_hash)
            rec.touched_run_id = @run_id
            rec.deleted = 0
            rec.save
          else
            begin
              rec = UsDhs.create(run_id: @run_id, title: title,
                                 teaser: teaser.to_s, article: article,
                                 link: link, location: location, date: date, contact_info: contact_info,
                                 data_source_url: "https://www.epa.gov/newsreleases/search/year/#{@folder}?search_api_views_fulltext=",
                                 touched_run_id: @run_id, deleted: 0, md5_hash: md5_hash)
            rescue StandardError => error
              pp error
              rec = UsDhs.find_by(link: link).update(run_id: @run_id, title: title,
                                                     teaser: teaser.to_s, article: article,
                                                     link: link, location: location, date: date, contact_info: contact_info,
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
end
