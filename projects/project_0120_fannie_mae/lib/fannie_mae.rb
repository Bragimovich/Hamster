# frozen_string_literal: true

require 'date'
require 'json'
require 'net/http'
require 'logger'

require_relative './database_manager'
require_relative '../models/fannie_mae'
require_relative '../models/fannie_mae_runs'

class FannieMaeScrape < Hamster::Harvester
  attr_accessor :request, :paid_proxies
  DIR_MAIN = '../HarvestStorehouse/project_0120/'
  URL = 'https://www.fanniemae.com'

  def main
    page_count = (get_max_count.gsub('Results 1 - 10 of ', '').to_f / 10).ceil

    fannie_mae_runs = FannieMaeRuns.new
    DatabaseManager.save_item(fannie_mae_runs)
    run_id = FannieMaeRuns.last.id

    page_count.times do |index|
      blocks = get_blocks(index)

      blocks.each do |block|
        parse_block(block.inner_html, run_id)
      end

      break if index + 1 == page_count
    end

    Hamster.report(to: 'dmitiry.suschinsky', message: '#120 Fannie Mae - EXPORT. Waiting for the source update...1 day')
  rescue SystemExit, Interrupt, StandardError => e
    Hamster.report(to: 'dmitiry.suschinsky', message: "#120 Fannie Mae - exception: #{e}!")
  end

  def parse_block(source, run_id)
    document = Nokogiri::HTML(source)
    title, subtitle, teaser, article, link, creator, type, country, date = nil

    return nil if document.class == NilClass

    date = document.css("//p[class='news-list__date']").text
    title = document.css("//div[class='news-list__title']").css('a').text
    teaser = document.css("//p[class='news-list__body']").text

    return nil if document.css("//div[class='news-list__title']").css('a').length == 0

    link = URL + document.css("//div[class='news-list__title']").css('a').first["href"]

    uri = URI.parse(link)
    source = connect_to(uri)
    doc = Nokogiri::HTML(source)

    subtitle = doc.css("//div[class='corp-h2 corp-subheading corp-subheading__news']").text
    article = doc.css("//article").css("div[class='body-field']").text

    # MAIN
    if title
      fannie_mae = FannieMae.new
      fannie_mae.date     = Date.parse(date)
      fannie_mae.title    = title
      fannie_mae.link     = link
      fannie_mae.teaser   = teaser
      fannie_mae.subtitle = subtitle
      fannie_mae.article  = article

      fannie_mae.run_id          = run_id
      fannie_mae.data_source_url = link

      fannie_mae_exist = FannieMae.where(
        title:    fannie_mae.title,
        link:     fannie_mae.link,
        teaser:   fannie_mae.teaser,
        subtitle: fannie_mae.subtitle,
        article:  fannie_mae.article,
        data_source_url:  fannie_mae.data_source_url,
        deleted: 0
      ).first

      if fannie_mae_exist.nil?
        fannie_mae.touched_run_id = run_id
        DatabaseManager.save_item(fannie_mae)
      else
        if fannie_mae_exist == fannie_mae
          fannie_mae.run_id         = run_id
          fannie_mae.touched_run_id = run_id
          DatabaseManager.save_item(fannie_mae)

          fannie_mae_exist.update(deleted: 1)
        else
          fannie_mae_exist.update(touched_run_id: run_id, date: Date.parse(date))
        end
      end

    end
  end

  def get_max_count
    uri = URI.parse(URL + '/newsroom/fannie-mae-news?page=0')
    source = connect_to(uri)

    @document = Nokogiri::HTML(source)
    @document.css("//span[class='news-filter__result-text']").text
  end

  def get_blocks(page_num)
    uri = URI.parse(URL + "/newsroom/fannie-mae-news?page=#{page_num}")
    source = connect_to(uri)

    @document = Nokogiri::HTML(source)
    @document.css("//tr[class='mb-3 news-list-item news-list__article']")
  end

  private

  def connect_to(uri)
    response = Net::HTTP.get_response(uri)
    response.body
  end
end
