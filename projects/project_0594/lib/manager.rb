# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

STORE_FOLDER = "#{ENV['HOME']}/HarvestStorehouse/project_0594/trash/courts_state_co_us/"

class Manager < Hamster::Harvester
  SUB_FOLDER = "courts_state_co_us"
  BASE_URL   = "https://www.courts.state.co.us"

  def initialize
    super
    @scraper = Scraper.new
    @parser  = Parser.new
  end

  def download(update: false)
    begin
      send_to_slack("Project #0594 download started")
      @scraper = Scraper.new
      @scraper.start(update)
      send_to_slack("Project #0594 download finished")
    rescue Exception => e
      send_to_slack("#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}")
    end
  end
  
  def store(update: false)
    begin
      send_to_slack("Project #0594 parse started")
      @parser = Parser.new
      @parser.start(update)
      send_to_slack("Project #0594 parse finished")
    rescue Exception => e
      send_to_slack("#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}")
    end
  end

  private

  def send_to_slack(message)
    Hamster.report(to: 'Robert Arnold', message: message , use: :slack)
  end
end