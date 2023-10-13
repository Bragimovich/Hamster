# frozen_string_literal: true

require_relative '../models/pledge_to_teach_the_truth'
require_relative '../models/pledge_to_teach_the_truth_runs'
require_relative '../models/temp_pledge_to_teach'

class Scraper < Hamster::Harvester
  LOGFILE = "#{ENV['HOME']}/cron_tasks/logs/project_0090_log"
  def initialize
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @md5 = Digest::MD5
    super
  end

  def main
    begin
      @start_time = Time.now
      assign_new_run
      @run_id = (PledgeTeachTruthRuns.maximum(:id).nil? ? 1 : PledgeTeachTruthRuns.maximum(:id))
      page_num = 1
      begin
        puts "Page #{page_num} processing".green
        page = get_page(page_num)
        result = parse_page(page)
        break if result == 0

        page_num += 1
        sleep(rand(1..5))
      end while result != 0
      check_deleted
      File.open(LOGFILE, 'a') do |name|
        name.puts "The script completed successfully at #{Time.now}"
      end
      Hamster.report to: 'URYM6LD9V', message: "#{Time.now.to_s} - Pledge to Teach the Truth completed successfully."
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      File.open(LOGFILE, 'a') do |name|
        name.puts "The script fall with error at #{Time.now}: \n#{e} | #{e.backtrace}"
      end
      Hamster.report to: 'URYM6LD9V', message: "#{Time.now.to_s} - Pledge to Teach the Truth - the script failled with error: \n#{e} | #{e.backtrace}."
    end
  end

  private
  def get_page(page_num)
    if page_num == 1
      link = "https://www.zinnedproject.org/news/pledge-to-teach-truth"
    else
      link = "https://www.zinnedproject.org/news/pledge-to-teach-truth?signature_page=#{page_num}"
    end
    begin
      request = Hamster.connect_to(
        url: link,
        headers: {
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
          'Sec-Fetch-Mode' => 'navigate',
          'Host' => 'www.zinnedproject.org'
        },
        proxy_filter: @proxy_filter,
        method: :get
      )
      raise if (request&.headers.nil? || (request&.status != 200))

    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      sleep(rand(5..10))
      if (@start_time + 9000) < Time.now
        Hamster.report to: 'URYM6LD9V', message: "#{Time.now.to_s} - Pledge to Teach the Truth - infinity loop. Aborted!"
        exit
      end
      retry
    end
    request.body
  end

  def parse_page(page)
    html = Nokogiri::HTML(page)
    signatures = html.css('.signature')
    return 0 if signatures.empty?
    signatures.each do |sign|
      city = ''
      state = ''

      signature = sign.at('.name')
      if !signature.nil?
        signature = signature.content.gsub("\t", '').strip
        if signature.include? "|"
          name, address = signature.split("|")

          if !address.nil?
            city = address.split(",")[0].strip
            state = address.split(",")[-1]
          end
        else
          name, state = signature.split(",")
          if !name.scan(/[A-Z]{2}$/).empty?
            state = name.scan(/[A-Z]{2}$/)[0]
            name = name[0, name.size - 2]
          end
        end
      end
      name = name.strip
      state = !state.nil? ? state.strip : state.to_s


      comment = sign.at('.comment')
      comment = comment.content.gsub("\xF0\x9F\x99\x82", '').encode!( 'UTF-8') if !comment.nil?
      comment = comment.to_s.strip

      fill_table(name, city, state, comment)
    end
  end

  def fill_table(name, city, state, comment)
    h = {}
    h[:name] = name
    h[:city] = city
    h[:state] = state
    h[:comment] = comment
    h[:last_scrape_date] = Date.today.to_s
    h[:next_scrape_date] = (Date.today + 1).to_s
    h[:run_id] = @run_id
    h[:touched_run_id] = @run_id
    md5 =  @md5.hexdigest "#{name}#{city}#{state}#{comment}"
    h[:md5_hash] = md5

    sign_info = PledgeTeachTruth.find_by(md5_hash: md5, deleted: false)
    if sign_info.nil?
      hash = PledgeTeachTruth.flail { |key| [key, h[key]] }
      PledgeTeachTruth.store(hash)
    else
      if sign_info.md5_hash == md5
        sign_info.update(touched_run_id: @run_id)
      else
        sign_info.update(deleted: true)
        hash = PledgeTeachTruth.flail { |key| [key, h[key]] }
        PledgeTeachTruth.store(hash)
      end
    end
  end

  def assign_new_run
    h = {}
    h[:status] = 'processing'
    hash = PledgeTeachTruthRuns.flail { |key| [key, h[key]] }
    PledgeTeachTruthRuns.store(hash)
  end

  def check_deleted
    PledgeTeachTruth.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    PledgeTeachTruthRuns.all.to_a.last.update(status: 'finished')
  end
end