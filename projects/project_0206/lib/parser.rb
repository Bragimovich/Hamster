# frozen_string_literal: true
require_relative 'keeper'
require_relative '../models/energy_ai'
require_relative '../models/energy_ceser'
require_relative '../models/energy_eere'
require_relative '../models/energy_em'
require_relative '../models/energy_fecm'
require_relative '../models/energy_indianenergy'
require_relative '../models/energy_lm'
require_relative '../models/energy_ne'
require_relative '../models/energy_oe'
#require 'scylla'
#require 'loofah'

class EnergyParser < Hamster::Parser
  def initialize(model)
    super
    @keeper = EnergyKeeper.new(model)
  end

  def get_news_links(pg)
    html = Nokogiri::HTML(pg)
    return 'all pages proceed' if html.css('.views-row').empty?
    links = proceed_main_info(html)
    links
  end

  def store
    files = peon.give_list(subfolder: 'releases')
    files.each do |file|
      data_page = peon.give(subfolder: 'releases', file: file)
      link = split_link(data_page)
      dept_model = get_model(data_page)
      news_page = split_html(data_page)
      article_info = parse_news_page(news_page)

      db = EnergyKeeper.new(dept_model)
      db.add_article(link, article_info)

      peon.move(file: file, from: 'releases', to: 'releases')
    end
    Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #206 US Dept of Energy offices news completed successfully."
  end

  private
  def proceed_main_info(html)
    links = html.css('.result-content h5 a').map{|i| i['href'].include?('https://') ? i['href'] : "https://www.energy.gov#{i['href']}"}
    titles = html.css('.result-content h5 a').map{|i| i&.content&.strip}
    teaseres = html.css('.result-content .search-result-summary').map{|i| i&.content&.strip}
    dates = html.css('.search-result-display-date').map{|i| i&.content}

    links.each_with_index do |link, i|

      title = titles[i].gsub("\u00A0", ' ').strip
      title = cut_title(title)
      dirty = check_dirty(title)
      date = dates[i]
      teaser = teaseres[i]&.gsub("\u00A0", ' ')
      teaser = TeaserCorrector.new(teaser).correct if teaser

      @keeper.fill_main_news_data(link, title, teaser, date, dirty)
    end
    links
  end

  def parse_news_page(page)
    html = Nokogiri::HTML(page)

    article = html.css('.field--body').map {|i| i.to_s.gsub("\u00A0", ' ').gsub("­", '')}
    article = article.join("\n")
    contact_info = html.css('.field--body p').map {|i| i.to_s.gsub("\u00A0", ' ').gsub("­", '')}
    contact_info = contact_info.select{|i| i.include?('Media Contact') || i.include?('MEDIA CONTACT')}[0]
    with_table = article.include?("<table") ? 1 : 0
    dirty = 1 if !article || article == ''

    [article, with_table, contact_info, dirty]
  end

  def cut_title(title)
    if title && title.size > 205
      title_end = title[0,201].rindex(' ')
      title = title[0, title_end] + "..."
    end
    title
  end

  #def check_dirty(article)
  #  return 1 if (article == '') || (article.language != 'english')
  #  0
  #end
  def check_dirty(title)
    chars = title.split('')
    non_englisch = []
    chars.each do |char|
      non_englisch << char if char.ord > 255
    end
    dirty = (non_englisch.size > 3) ? 1 : 0
    dirty
  end

  def move_to_trash(file)
    peon.move(file: file, from: 'releases', to: 'releases')
  end

  def split_model(file_content)
    file_content.split('|||').first
  end

  def split_link(file_content)
    file_content.split('|||')[1]
  end

  def split_html(file_content)
    file_content.split('|||').last
  end

  def get_model(file_content)
    raw = split_model(file_content)
    model = case raw
            when 'EnergyAI'
              EnergyAI
            when 'EnergyCESER'
              EnergyCESER
            when 'EnergyNE'
              EnergyNE
            when 'EnergyLM'
              EnergyLM
            when 'EnergyFECM'
              EnergyFECM
            when 'EnergyEM'
              EnergyEM
            when 'EnergyEERE'
              EnergyEERE
            when 'EnergyIndianenergy'
              EnergyIndianenergy
            when 'EnergyOE'
              EnergyOE
            end
    model
  end
end