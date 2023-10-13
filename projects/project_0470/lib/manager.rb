# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class CourtListener < Hamster::Harvester
  def initialize
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @path = "#{@scraper.storehouse}store/"
  end

  def parse(links, filename)
    res = nil
    links.each do |api_url|
      # 1.upto(MAX_PAGES) do |page|
      (1..MAX_PAGES).step(1).each do |page|
        url = "#{api_url}&page=#{page}"
        res = Parser.new.parse_key(Scraper.new.get_source(url), 'results')
        return if !res # NilClass check, if number of records is a multiplicity of 20
        Scraper.new.store_to_csv(res, filename)
        return if res.size < RECORDS_PER_PAGE
      end
    end
    res
  end

  def parse_all(endpoint)
    param = endpoint.eql?('courts') ? 'date_modified' : 'date_created'
    next_date = '2000-01-01T00:00:00'
    loop do
      link = "#{API_URL}#{endpoint}/?format=json&#{param}__gt=#{next_date}&order_by=#{param}"
      res = parse([link], "cl_raw_#{endpoint}.csv")
      break if !res # exit from loop if no more records

      next_date = res.last[param.to_s]
    end
  end

  def parse_all_modified(endpoint)
    where_condition = endpoint.eql?('opinions') ? "sha1 != ''" : "1=1"
    records = @keeper.select('id', "cl_#{endpoint}", "#{where_condition} order by id desc limit 1")
    next_id = records.first
    records = @keeper.select('date_modified', "cl_#{endpoint}", "id = #{next_id}")
    next_date = records.first.to_s.split[0..1].join('T')

    if endpoint.eql?('dockets')
      records = @keeper.select('cl_court_id', 'cl_courts_clean', 'court_id is not null')
      records.each do |court_id| # don't parse "sort by id asc & desc"
        where_condition = "court_id = '#{court_id}'"
        court_records = @keeper.select('id', "cl_#{endpoint}", "#{where_condition} order by id desc limit 1")
        next_id = court_records.empty? ? 1 : court_records.first
        court_records = @keeper.select('date_modified', "cl_#{endpoint}", "id = #{next_id}")
        next_date = court_records.first.to_s.split[0..1].join('T')
        # date = '2022-09-01T00:00:01'

        loop do
          link = "#{API_URL}#{endpoint}/?format=json&date_modified__gt=#{next_date}&date_filed__gte=2020-01-01&court__id=#{court_id}&order_by=date_modified"
          res = parse([link], "cl_mod_#{endpoint}.csv")
          break if !res # exit from loop if no more records

          next_date = res.last["date_modified"]
        end
      end
    else
      loop do
        link = "#{API_URL}#{endpoint}/?format=json&date_modified__gt=#{next_date}&order_by=date_modified"
        res = parse([link], "cl_mod_#{endpoint}.csv")
        break if !res # exit from loop if no more records

        next_date = res.last["date_modified"]
      end
    end
  end

  def parse_by_api
    now = Time.now
    @scraper.clear # remove old *.csv to trash
    parse_all('courts')
    parse_all('people')
    parse_all('positions')
    parse_all('educations')
    parse_all('political-affiliations')
    parse(SCHOOL_LINKS, 'cl_raw_schools.csv') # too many schools have the same date_created and date_modified value

    @keeper.store_raw_courts("#{@path}cl_raw_courts.csv", 'cl_raw_courts')
    @keeper.store_raw_political_affiliation("#{@path}cl_raw_political-affiliations.csv", 'cl_raw_judge_political_affiliation')
    @keeper.store_raw_schools("#{@path}cl_raw_schools.csv", 'cl_raw_schools')
    @keeper.store_raw_education("#{@path}cl_raw_educations.csv", 'cl_raw_judge_schools')
    @keeper.store_raw_persons("#{@path}cl_raw_people.csv", 'cl_raw_judge_info')
    @keeper.store_raw_positions("#{@path}cl_raw_positions.csv", 'cl_raw_judge_job')

    parse_all_modified('clusters')
    parse_all_modified('opinions')
    parse_all_modified('dockets')

    @keeper.store_raw_clusters("#{@path}cl_mod_clusters.csv", 'cl_raw_clusters')
    @keeper.store_raw_opinions("#{@path}cl_mod_opinions.csv", 'cl_raw_opinions')
    @keeper.store_raw_dockets("#{@path}cl_mod_dockets.csv", 'cl_raw_dockets')

    puts '*'*77, now, Time.now
  end

  def store
    @keeper.store
    %w(clusters opinions dockets).each do |name|
      @keeper.set_deleted(name)
      @keeper.store_as_is(name)
      @keeper.clear_raw_data("cl_raw_#{name}")
    end
    @scraper.clear # remove old *.csv to trash
  end
end
