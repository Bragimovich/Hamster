require_relative 'maxpreps_com_keeper'
require_relative 'maxpreps_com_scraper'
require_relative 'maxpreps_com_parser'
require 'pry'

class MaxprepsComManager < Hamster::Harvester
  TASK_NAME = '#506 Scrape Maxpreps.com'.freeze
  SLACK_ID  = 'Eldar Eminov'.freeze
  HOST      = 'www.maxpreps.com'.freeze

  def initialize(**params)
    super
    @keeper = MaxprepsComKeeper.new
  end

  def download
    scraper = MaxprepsComScraper.new(keeper)
    scraper.scrape_site
    count = scraper.count
    message = "#{TASK_NAME} --download\nCompleted scraping #{Time.now}.\n"
    message += count.zero? ? "There is no new data on the #{HOST} website." : "Total scraped on the site #{HOST}: #{count}."
    success_message(message)
  end

  def store
    run_id       = keeper.run_id
    gender       = 'boys'
    sport        = 'baseball'
    schools_name = peon.give_list(subfolder: "#{run_id}_#{gender}_#{sport}_schools_page")
    schools_name.each do |school_name|
      school_page = peon.give(file: school_name, subfolder: "#{run_id}_#{gender}_#{sport}_schools_page")
      parser  = MaxprepsComParser.new(html: school_page)
      schools = parser.parse_schools
      schools.each_with_index do |school, idx|
        puts "School ##{idx}".green
        keeper.save_school(school)
        md5 = MD5Hash.new(columns: [:url])
        md5.generate(url: school[:data_source_url])
        ###########################
        puts school[:data_source_url]
        ############################
        school_md5   = md5.hash
        player_pages = peon.give_list(subfolder: "#{run_id}_#{gender}_#{sport}_#{school_md5}_player_pages")
        player_pages.each do |name|
          page   = peon.give(file: name, subfolder: "#{run_id}_#{gender}_#{sport}_#{school_md5}_player_pages")
          parser = MaxprepsComParser.new(html: page)
          player = parser.parse_player
          keeper.save_player(player)
        end

=begin
        score_pages = peon.give_list(subfolder: "#{run_id}_#{gender}_#{sport}_#{school_md5}_scores_pages")
        score_pages.each do |name|
          page   = peon.give(file: name, subfolder: "#{run_id}_#{gender}_#{sport}_#{school_md5}_scores_pages")
          parser = MaxprepsComParser.new(html: page)
          player = parser.parse_score
          keeper.save_score(player)
        end
=end
      end
    end
    message = 'End parsing'
    success_message(message)
  rescue StandardError => e
    puts "#{e} | #{e.backtrace}"
    Hamster.report(to: 'Eldar Eminov', message: e, use: :both)
  end


  private

  attr_accessor :keeper

  def success_message(message)
    puts message.green
    Hamster.report(to: SLACK_ID, message: message, use: :both)
  end
end
