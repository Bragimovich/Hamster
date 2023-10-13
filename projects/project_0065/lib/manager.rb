# frozen_string_literal: true

require_relative '../lib/connect'
require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester
  def initialize(args)
    super
    @keeper = Keeper.new(args)
    @case_type = ["AP","CV","EX","JG","LP","MS","DR"]
    time = (Time.now).strftime("%Y").split('').last(2).join.to_i
    @files = peon.give_list.sort.map { |file| file} if args[:store]

    if args[:download] || args[:auto]
      first_year = 20
      first_year = args[:start] if args[:start].present?
      @data_range = (first_year..time).map {|time| time}
      #@data_range = range.reverse
    elsif args[:update]
      @data_range = [time]
      @object = Oh10thAcCaseInfo
      download(args)
      @object = OhFcccCaseInfo
      download(args)
    end

    if args[:single].nil? && args[:store]
      part  = @files.size / args[:instances] + 1
      @files = @files[(args[:instance] * part)...((args[:instance] + 1) * part)]
    elsif args[:single].nil? && args[:download]
      part  = @data_range.size / args[:instances] + 1
      @data_range = @data_range[(args[:instance] * part)...((args[:instance] + 1) * part)]
    end
  end

  def download(args)
    queue = Queue.new
    thr1 = Thread.new do
      scraper = Scraper.new(args)
      @data_range.each do |year|
        @case_type.each do |type|
          @forward = ["#{year}","#{type}","000000"] if args[:download] || args[:auto]
          search_last_case(year, type) if args[:update]
          scraper.type = type
          scraper.year = year
          loop do
            @logger.info("#{year}")
            page = scraper.search(@forward)
            (page.first).nil? ? break : @forward =  Parser.new(page.first).check_next_page
            unless page.last.nil?
              sleep 100 if queue.size > 50
              queue.push(page)
            end
          end
        end
      end
    end

    thr2 = Thread.new do
      loop do
        page = queue.pop
        store_to_db(page)
        break if !thr1.alive? && queue.empty?
      end
    end
    thr1.join
    thr2.join

    if !thr2.alive? && !thr1.alive?
      @keeper.update_delete_status unless args[:update]
      @keeper.finish
    end
  end

  def store(args)
    @files.each_with_index do |file, index|
      store_to_db([peon.give(file: file), file])
    end
    @keeper.update_delete_status unless args[:update]
    @keeper.finish
  end

  def store_to_db(file)
    case_type = file.last.gsub("-","").scan(/(\d{2})(\w{2})(\d{6})/).flatten[1]
    @logger.info(case_type)
    parser = Parser.new(file.first)
    parser.type = case_type
    @keeper.type = case_type
    @keeper.data_hash = parser.appellate_cases_data if case_type == "AP"
    @keeper.data_hash = parser.domestic_cases_data if case_type == "DR"
    @keeper.data_hash = parser.civil_cases_data if case_type == "CV" || case_type == "EX" || case_type == "JG" || case_type == "LP" || case_type == "MS"
    @keeper.store_info
    @keeper.store_activities
    @keeper.store_party
    @keeper.store_judgment if case_type != "AP"
    @keeper.store_additional_info if case_type == "AP"
    @keeper.store_aws
    clear(file.last) rescue nil
  end

  def update_desc(args)
    @scraper = Scraper.new(args)
    search_desc(Oh10thAcCaseInfo, Oh10thAcCaseParty, args)
    search_desc(OhFcccCaseInfo, OhFcccCaseParty, args)
  end

  def update_aws(args)
    store_pdf(OhFcccCasePdfsOnAws, args)
    store_pdf(Oh10thAcCasePdfsOnAws, args)
    @keeper.store_relations_activity
    @keeper.store_relations_info
  end

  def store_pdf(object, args)
    scraper = Scraper.new(args)
    pdf_link = object.select(:source_link).where(aws_link: nil ).limit(50000).pluck(:case_id, :source_link)
    unless pdf_link.empty?
      pdf_link.each do |value|
        @keeper.update_aws_link(scraper.store_to_aws(value), value, object)
      end
    end
  end

  def search_desc(object_info, object_party, args)
    case_id_arr = object_info.select(:case_id).where(case_name: nil ).limit(50000).pluck(:case_id, :case_filed_date)
    unless case_id_arr.empty?
      case_id_arr.each do |value|
        date = (value[1]).strftime("%m/%d/%Y") 
        case_type = value[0].split[1]
        object_party.where(case_id: value[0]).pluck(:party_name).each do |name|
          search_name = check_name(name)
          unless search_name.nil?
            content = @scraper.send_request(search_name, date, case_type)
            parser = Parser.new(content.body) 
            desc_hash = parser.description(case_type)
            @keeper.store_description(desc_hash, object_info)
          end
        end
      end
    end
  end

  def search_last_case(year, type)
    last_case = @object.select(:case_id).where("case_id like '%#{type}%'").order(:created_at).last.case_id
    num = last_case.scan(/(\d{2}) (\w{2}) (\d{6})/).flatten[2]
    num.to_i - 20 < 0 ? num = "000000" : num.to_i - 20
    @forward = ["#{year}","#{type}","#{num}"]
  end

  def check_name(name)
    if name.include?("LCC") || name.include?("&") || name.include?("OHIO") || name.include?("LTD") || name.include?("USA") || name.include?("INC") || name.include?("TAX") || !name.scan(/\d/).empty? || name.include?("BANK") || name.include?("DIV") || name.include?("COUNTY") || name.include?("UNKNOWN") || name.include?("UNITED") || name.include?("FRANKLIN") || name.include?("AND") || name.include?("CLERK") || name.include?("JUDGE") || name.include?("OFFICE")
      name
    elsif  name.include?("NO ATTORNEY ON RECORD")
      return nil
    else
      name.split.delete_if {|el| el if el.size < 3}
    end
  end

  def clear(file)
    trash_folder = "Franklin_County_Court_Case_trash"
    peon.move(file: file, to: trash_folder)
  end
end
