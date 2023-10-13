# frozen_string_literal: true

require_relative '../models/heerf_relief_funds_by_states'
require_relative '../models/heerf_relief_funds_institutions'
require_relative '../models/heerf_relief_funds_allocations'
require_relative '../models/heerf_relief_funds_runs'

class Scraper < Hamster::Harvester
  def initialize
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @md5 = Digest::MD5
    super
  end

  LOGFILE = "#{ENV['HOME']}/cron_tasks/logs/project_0084_log"

  def main
    begin
      assign_new_run
      @run_id = (HEERFReliefIRuns.maximum(:id).nil? ? 1 : HEERFReliefIRuns.maximum(:id))
      @last_scrape_date = Date.today.to_s
      @next_scrape_date = (Date.today + 30).to_s
      get_cookie
      get_states
      proceed_site_data
      check_deleted
      File.open(LOGFILE, 'a') do |name|
        name.puts "The script completed successfully at #{Time.now}"
      end
      Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - HEERF relief funds completed successfully."
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      File.open(LOGFILE, 'a') do |name|
        name.puts "The script fall with error at #{Time.now}: \n#{e} | #{e.backtrace}"
      end
      Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - HEERF relief funds failed with error - #{e} | #{e.backtrace}."
    end
  end

  private
  def proceed_site_data
    begin
      @start_time = Time.now
      req_tocken = get_req_tocken(@html)
      raise if Time.now > (@start_time + 30000)
      @states.each do |state|
        req_param = "csrfmiddlewaretoken=#{req_tocken}&inputState=#{state}"
        referer = 'https://www.randoland.us/wastebooks/heerf/'
        link = "https://www.randoland.us/wastebooks/heerf-state/"
        raise if Time.now > (@start_time + 30000)
        @state_page = post_method(link, req_param, referer, @cookie)
        @state_html = Nokogiri::HTML(@state_page.body)
        state_total_relief = get_state_total_relief
        state_id = fill_state_table(state, state_total_relief)
        get_institution_ids
        new_tocken = get_req_tocken(@state_html)

        @institution_ids.each do |id|
          req_param = "csrfmiddlewaretoken=#{new_tocken}&inputInst=#{id}"
          referer = "https://www.randoland.us/wastebooks/heerf-state/"
          link = "https://www.randoland.us/wastebooks/heerf-inst/"
          raise if Time.now > (@start_time + 30000)
          institution_page = post_method(link, req_param, referer, @cookie)
          institution_html = Nokogiri::HTML(institution_page.body)
          institution_name = get_institution_name(institution_html)
          institution_total_relief = get_istitution_total_relief(institution_html)
          total_per_bill = get_bills_data(institution_html)
          institution_id = fill_institutions_table(state_id, institution_name, institution_total_relief)
          total_per_bill.each do |bill_row|
            raise if Time.now > (@start_time + 30000)
            bill_data = bill_row.split(':')
            bill = bill_data[0]
            bill_total_relief = bill_data[1].gsub('$', '').strip
            fill_allocations_table(institution_id, bill, bill_total_relief)
          end
          sleep(rand(1..2))
        end
      end
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      File.open(LOGFILE, 'a') do |name|
        name.puts "The script fall with error at #{Time.now}: \n#{e} | #{e.backtrace}"
      end
      Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - HEERF relief funds failed with error - #{e} | #{e.backtrace}."
    end
  end

  def get_bills_data(html)
    bills = html.css('.pt-4 h5').map{|i| i.content}
    bills
  end

  def get_istitution_total_relief(html)
    institution_total_relief = html.at('.pt-4 h2').content
    if !institution_total_relief.nil?
      institution_total_relief = institution_total_relief.split("$")[1]
    end
    institution_total_relief
  end

  def get_institution_name(html)
    name = html.at('h2').content
    name
  end

  def get_institution_ids
    @institution_ids = @state_html.css('#inputInst option').map{|i| i['value']}
    @institution_ids.slice!(0)
  end

  def get_state_total_relief
    total_relief = @state_html.css('.container-fluid h4').map{|i| i.content}
    total_relief = total_relief.select{|i| i.include? "Total Relief"}
    if !total_relief.empty?
      st_total_relief = total_relief[0].split("$")[1]
    end
    st_total_relief
  end

  def get_req_tocken(html)
    tocken = html.at('input[name="csrfmiddlewaretoken"]')['value']
    tocken
  end

  def get_states
    @html = Nokogiri::HTML(@start_page.body)
    @states = @html.css('#inputState option').map{|i| i.content}
    @states.slice!(0)
  end

  def get_cookie
    @start_page = get_start_page
    @cookie = @start_page.headers['set-cookie']
  end

  def get_start_page
    page = get_method
    page
  end

  def get_method
    begin
      request = Hamster.connect_to(
        url: "https://www.randoland.us/wastebooks/heerf/",
        headers: {
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
          'Sec-Fetch-Mode' => 'navigate',
          'Host' => 'www.randoland.us'
        },
        proxy_filter: @proxy_filter,
        ssl_verify: false,
        method: :get
      )
      raise if request&.headers.nil?

    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      sleep(rand(5..10))
      retry
    end
    request
  end

  def post_method(link, param, ref, cook)
    begin
      request = Hamster.connect_to(
        url: link,
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
          'Origin' => 'https://www.randoland.us',
          'Referer' => ref,
          'X-Requested-With' => 'XMLHttpRequest',
          'Sec-Fetch-Mode' => 'cors',
          'Host' => 'www.randoland.us',
          'Cookie' => "#{cook}"
        },
        req_body: param,
        proxy_filter: @proxy_filter,
        ssl_verify: false,
        method: :post
      )

      raise if request&.headers.nil?
      if [301, 302, 403, 404].include?(request&.status)
        pause = 100
        puts "Restart connection after #{pause} seconds."
        sleep(pause)
      end
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      sleep(rand(5..10))
      retry
    end
    request
  end

  def fill_state_table(state, total_relief)
    h = {}
    h[:state] = state
    h[:total_relief] = total_relief
    h[:total_relief_numeric] = total_relief.gsub(",", '').to_i
    h[:last_scrape_date] = @last_scrape_date
    h[:next_scrape_date] = @next_scrape_date
    h[:run_id] = @run_id
    h[:touched_run_id] = @run_id
    md5 =  @md5.hexdigest "#{state}#{total_relief}"
    h[:md5_hash] = md5

    state_info = HEERFReliefStates.find_by(md5_hash: md5, deleted: false)
    if state_info.nil?
      hash = HEERFReliefStates.flail { |key| [key, h[key]] }
      HEERFReliefStates.store(hash)
    else
      state_info.update(touched_run_id: @run_id)
    end
    state_id = HEERFReliefStates.find_by(state: state, md5_hash: md5, deleted: false)[:id]
    state_id
  end

  def fill_institutions_table(state_id, institution, total_relief)
    h = {}
    h[:state_id] = state_id
    h[:institution] = institution
    h[:total_relief] = total_relief
    h[:total_relief_numeric] = total_relief.gsub(",", '').to_i
    h[:last_scrape_date] = @last_scrape_date
    h[:next_scrape_date] = @next_scrape_date
    h[:run_id] = @run_id
    h[:touched_run_id] = @run_id
    md5 =  @md5.hexdigest "#{institution}#{total_relief}"
    h[:md5_hash] = md5

    institution_info = HEERFReliefInstitutions.find_by(state_id: state_id, md5_hash: md5, deleted: false)
    if institution_info.nil?
      hash = HEERFReliefInstitutions.flail { |key| [key, h[key]] }
      HEERFReliefInstitutions.store(hash)
    else
      institution_info.update(touched_run_id: @run_id)
      # HEERFReliefInstitutions.where(["deleted = :deleted and state_id = :state_id and md5_hash = :md5_hash and touched_run_id != :touched_run_id", { deleted: false, state_id: state_id, md5_hash: md5, touched_run_id: @run_id}]).to_a.first.update(touched_run_id: @run_id)
    end
    institution_id = HEERFReliefInstitutions.find_by(state_id: state_id, md5_hash: md5, deleted: false, touched_run_id: @run_id)[:id]
    #institution_id = HEERFReliefInstitutions.where(["institution = :institution and state_id = :state_id and touched_run_id = :touched_run_id and md5_hash = :md5_hash and deleted = :deleted", {institution: institution, state_id: state_id, touched_run_id: @run_id, md5_hash: md5, deleted: false}]).to_a.last[:id]
    institution_id
  end

  def fill_allocations_table(institution_id, bill, total_relief)
    h = {}
    h[:institution_id] = institution_id
    h[:bill] = bill
    h[:total_relief] = total_relief
    h[:total_relief_numeric] = total_relief.gsub(",", '').to_i
    h[:last_scrape_date] = @last_scrape_date
    h[:next_scrape_date] = @next_scrape_date
    h[:run_id] = @run_id
    h[:touched_run_id] = @run_id
    md5 =  @md5.hexdigest "#{bill}#{total_relief}"
    h[:md5_hash] = md5

    allocation_info = HEERFReliefIAllocations.find_by(institution_id: institution_id, md5_hash: md5, deleted: false)
    if allocation_info.nil?
      hash = HEERFReliefIAllocations.flail { |key| [key, h[key]] }
      HEERFReliefIAllocations.store(hash)
    else
      allocation_info.update(touched_run_id: @run_id)
    end
  end

  def check_deleted
    HEERFReliefStates.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    HEERFReliefInstitutions.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    HEERFReliefIAllocations.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    HEERFReliefIRuns.all.to_a.last.update(status: 'finished')
  end

  def assign_new_run
    h = {}
    h[:status] = 'processing'
    hash = HEERFReliefIRuns.flail { |key| [key, h[key]] }
    HEERFReliefIRuns.store(hash)
  end
end
