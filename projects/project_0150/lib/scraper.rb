# frozen_string_literal: true
require 'csv'

require_relative '../models/georgia_sex_offenders'
require_relative '../models/georgia_sex_offenders_runs'

class Scraper < Hamster::Harvester
  def initialize
    super
    @md5 = Digest::MD5
    @store = "#{ENV['HOME']}/HarvestStorehouse/project_0150/store/#{Date.today.to_s}"
    @csv_report = "#{ENV['HOME']}/HarvestStorehouse/project_0150/store/#{Date.today.to_s}/csv_report"
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
  end

  SOURCE_LINK = "https://state.sor.gbi.ga.gov/SORT_PUBLIC/sor.csv"
  HOST = "state.sor.gbi.ga.gov"

  CSV_HEADERS =          ['NAME',
                          'SEX',
                          'RACE',
                          'YEAR OF BIRTH',
                          'HEIGHT',
                          'WEIGHT',
                          'HAIR COLOR',
                          'EYE COLOR',
                          'STREET NUMBER',
                          'STREET',
                          'CITY',
                          'STATE',
                          'ZIP CODE',
                          'COUNTY',
                          'REGISTRATION DATE',
                          'CRIME',
                          'CONVICTION DATE',
                          'CONVICTION STATE',
                          'INCARCERATED',
                          'PREDATOR',
                          'ABSCONDER',
                          'RES VERIFICATION DATE',
                          'LEVELING'
  ]

  def main
    begin
      puts "Start!".green
      assign_new_run if GeorgiaSexOffendersRuns.all.to_a.last[:status] == 'finished'
      @last_scrape_date = Date.today.to_s
      @next_scrape_date = (Date.today + 30).to_s
      @run_id = (GeorgiaSexOffendersRuns.maximum(:id).nil? ? 1 : GeorgiaSexOffendersRuns.maximum(:id))
      @start_time = Time.now
      puts "Load Georgia sex offenders csv file".green
      csv_file = get_page(HOST, SOURCE_LINK)
      create_source_directory

      File.open(@csv_report, 'a') do |name|
        name.puts csv_file
      end

      csv = CSV.parse(csv_file, headers: true, quote_empty: true)
      headers = csv.headers
      unless check_csv_headers(headers)
        puts "Bad data"
      end

      puts "Procees Georgia sex offenders csv file".green

      process_data(csv)
      check_deleted

      Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #150 Georgia Sex Offenders completed successfully."
      return 0
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #150 Georgia Sex Offenders failed - #{e} | #{e.backtrace}"
    end
  end

  private
  def process_data(csv)
    csv.each do |row|
      h = {}
      h[:name] = row[CSV_HEADERS[0]]&.strip if row[CSV_HEADERS[0]] != ' '
      h[:sex] = row[CSV_HEADERS[1]]&.strip if row[CSV_HEADERS[1]] != ' '
      h[:race] = row[CSV_HEADERS[2]]&.strip  if row[CSV_HEADERS[2]] != ' '
      h[:year_of_birth] = row[CSV_HEADERS[3]]&.to_i if row[CSV_HEADERS[3]] != ' '
      h[:eye_color] = row[CSV_HEADERS[7]]&.strip if row[CSV_HEADERS[7]] != ' '
      h[:street_number] = row[CSV_HEADERS[8]]&.strip if row[CSV_HEADERS[8]] != ' '
      h[:street] = row[CSV_HEADERS[9]]&.strip if row[CSV_HEADERS[9]] != ' '
      h[:zip_code] = row[CSV_HEADERS[12]]&.strip if row[CSV_HEADERS[12]] != ' '
      h[:crime] = row[CSV_HEADERS[15]]&.strip if row[CSV_HEADERS[15]] != ' '
      h[:conviction_date] = format_date(row[CSV_HEADERS[16]]) if row[CSV_HEADERS[16]] != ' '
      md5_uniq = md5_calculate(h)

      h[:height] = row[CSV_HEADERS[4]]&.to_i if row[CSV_HEADERS[4]] != ' '
      h[:weight] = row[CSV_HEADERS[5]]&.to_i if row[CSV_HEADERS[5]] != ' '
      h[:hair_color] = row[CSV_HEADERS[6]]&.strip if row[CSV_HEADERS[6]] != ' '
      h[:city] = row[CSV_HEADERS[10]]&.strip if row[CSV_HEADERS[10]] != ' '
      h[:state] = row[CSV_HEADERS[11]]&.strip if row[CSV_HEADERS[11]] != ' '
      h[:zip_code] = row[CSV_HEADERS[12]]&.strip if row[CSV_HEADERS[12]] != ' '
      h[:county] = row[CSV_HEADERS[13]]&.strip if row[CSV_HEADERS[13]] != ' '
      h[:registration_date] = format_date(row[CSV_HEADERS[14]]) if row[CSV_HEADERS[14]] != ' '
      h[:conviction_state] = row[CSV_HEADERS[17]]&.strip if row[CSV_HEADERS[17]] != ' '
      h[:incarcerated] = row[CSV_HEADERS[18]]&.strip if row[CSV_HEADERS[18]] != ' '
      h[:predator] = row[CSV_HEADERS[19]]&.strip if row[CSV_HEADERS[19]] != ' '
      h[:absconder] = row[CSV_HEADERS[20]]&.strip if row[CSV_HEADERS[20]] != ' '
      h[:res_verification_date] = format_date(row[CSV_HEADERS[21]]) if row[CSV_HEADERS[21]] != ' '
      h[:leveling] = row[CSV_HEADERS[22]]&.strip if row[CSV_HEADERS[22]] != ' '
      md5 = md5_calculate(h)

      h[:md5_hash] = md5
      h[:md5_uniq] = md5_uniq
      h[:last_scrape_date] = @last_scrape_date
      h[:next_scrape_date] = @next_scrape_date
      h[:run_id] = @run_id
      h[:touched_run_id] = @run_id

      uniq_offender = GeorgiaSexOffenders.find_by(md5_uniq: md5_uniq, touched_run_id: @run_id, deleted: false)

      if uniq_offender.nil?
        exist_info = GeorgiaSexOffenders.find_by(md5_hash: md5, deleted: false)

        if exist_info.nil?
          hash = GeorgiaSexOffenders.flail { |key| [key, h[key]] }
          GeorgiaSexOffenders.store(hash)
        else
          exist_info.update(touched_run_id: @run_id)
        end
      else
        Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #150 Georgia Sex Offenders has duplicates - #{h[:name]}"
      end
    end
  end

  def format_date(date)
    formated = nil
    if (!date.nil? && date != '' && (date.size == 8))
      year = date[0, 4]
      month = date[4, 2]
      day = date[6, 2]
      formated = "#{year}-#{month}-#{day}"
    end
    formated
  end

  def md5_calculate(hash)
    uniq_key_data = ""
    hash.sort.to_h.each_value {|val| uniq_key_data += val.to_s}
    md5_hash = @md5.hexdigest uniq_key_data
    md5_hash
  end

  def get_page(host, link)
    begin
      request = Hamster.connect_to(
        url: link,
        headers: {
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
          'Sec-Fetch-Mode' => 'navigate',
          'Host' => host
        },
        proxy_filter: @proxy_filter,
        method: :get
      )
      raise if request&.headers.nil?

    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      sleep(rand(5..10))
      if (@start_time + 3600) < Time.now
        Hamster.report to: 'URYM6LD9V', message: "#{Time.now} - #150 Georgia Sex Offenders failed - infinity loop."
        exit
      end
      retry
    end
    request.body
  end

  def check_csv_headers(csv_headers)
    if (CSV_HEADERS == csv_headers)
      puts "Process Georgia Sex Offenders file. Headers are same!!!"
    else
      puts "CSV headers changed!!!"
      return false
    end
    true
  end

  def create_source_directory
    dir_name =  @store
    FileUtils.mkdir_p dir_name unless  File.directory?(dir_name)
  end

  def assign_new_run
    h = {}
    h[:status] = 'processing'
    hash = GeorgiaSexOffendersRuns.flail { |key| [key, h[key]] }
    GeorgiaSexOffendersRuns.store(hash)
  end

  def check_deleted
    GeorgiaSexOffenders.where(["deleted = :deleted and touched_run_id != :touched_run_id", { deleted: false, touched_run_id: @run_id}]).update(deleted: true)
    GeorgiaSexOffendersRuns.all.to_a.last.update(status: 'finished')
  end
end
