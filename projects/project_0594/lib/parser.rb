# frozen_string_literal: true
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Parser < Hamster::Harvester

  SOURCE = "https://www.courts.state.co.us"
  STORE_FOLDER = "#{ENV['HOME']}/HarvestStorehouse/project_0594/trash"
  INFO_FOLDER = "info_co_saac_case_us"
  ACTIVITY_FOLDER = "activity_co_saac_case_us"
  
  def initialize(*_)
    super
    @court_id = 413
    @keeper  = Keeper.new
    @scraper = Scraper.new
    @aws_s3   = AwsS3.new(bucket_key = :us_court)
    @s3 = AwsS3.new(bucket_key = :us_court)
  end
  
  def start(update)
    @keeper  = Keeper.new
    @scraper = Scraper.new
    send_to_slack("Project #0594 store started")
    log_store_started
    parser
    store
    log_store_finished
    send_to_slack("Project #0594 store finished")
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in start:\n#{e.inspect}")
  end

  private

  def parser
    parse_idx_pdfs
  end

  def store
    @keeper.update_touch_run_id(@md5_array)
    @keeper.store_all(@co_info, "info")
    @keeper.store_all(@co_party, "party")
    @keeper.store_all(@co_activities, "activities")
    @keeper.store_all(@co_add_info, "add_info")
    @keeper.store_all(@co_pdfs_on_aws, "pdfs_on_aws")
    @keeper.store_all(@co_rel_info_pdf, "rel_info_pdf")
    @keeper.store_all(@co_rel_act_pdf, "rel_act_pdf")
    @keeper.delete_history
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in store:\n#{e.inspect}")
  end

  def parse_idx_pdfs
    idx_files = peon.list(subfolder: INFO_FOLDER)
    i = 0
    idx_files.each do |idx_file|
      @co_info, @co_party, @co_activities, @co_pdfs_on_aws, @activity_pdfs_on_aws, @md5_array, 
      @co_add_info, @co_rel_info_pdf, @co_rel_act_pdf, @info_pdfs_on_aws = [], [], [], [], [], [], [], [], [], []
      parse_index(idx_file)
      update_md5_hash
      store
      i += 1
    end
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_idx_pdfs:\n#{e.inspect}")
  end

  def unzip_file(filename, path)
    peon.move_and_unzip_temp(file: filename, from: "#{path}/", to: "#{path}/")
    filename = filename.gsub(".gz", "")
    filename
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in unzip_file:\n#{e.inspect}")
  end

  # check type of files and specify path according to type
  def parse_index(file)
    if file.include?("\.htm")
      parse_htm(file)
    else
      parse_pdf(file)
    end
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_index:\n#{e.inspect}")
  end
  
  # method to parse pdf files
  def parse_pdf(file)
    reader = PDF::Reader.new("#{STORE_FOLDER}/#{INFO_FOLDER}/#{file}")
    inside_hyperlinks = inside_pdfs(reader)
    content = get_content(reader)
    parse_case(content, file)
    store_inside_hyperlinks(inside_hyperlinks)
    parse_idx_activity unless inside_hyperlinks.length == 0
  end
  
  # method to parse htm files
  def parse_htm(file) 
    htm = Nokogiri::HTML.parse(File.open("#{STORE_FOLDER}/#{INFO_FOLDER}/#{file}"))
    inside_hyperlinks = inside_pdfs_htm(htm)
    parse_htm_case(htm, file)
    store_inside_hyperlinks(inside_hyperlinks)
    parse_idx_activity unless inside_hyperlinks.length == 0
  end
  
  def parse_idx_activity
    idx_files = peon.give_list(subfolder: ACTIVITY_FOLDER)
    idx_files = idx_files.map{ |file| unzip_file(file, ACTIVITY_FOLDER) }
    idx_files.each do |idx_file|
      next if idx_file.include?("file\:\/\/\/")
      parse_index_activity(idx_file)
    end
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_idx_activity:\n#{e.inspect}")
  end
  
  def update_md5_hash
    @co_add_info = @co_add_info.map{ |hash| add_md5_hash(hash) } unless @co_add_info.nil?
    @activity_pdfs_on_aws = @activity_pdfs_on_aws.map{ |hash| add_md5_hash(hash) } unless @activity_pdfs_on_aws.nil?
    @co_activities = @co_activities.map{ |hash| add_md5_hash(hash) } unless @co_activities.nil?
    rel_act_pdf = get_rel_act_pdf() unless @co_activities.nil?
    @co_rel_act_pdf = rel_act_pdf unless rel_act_pdf.nil?
    @co_pdfs_on_aws.concat(@activity_pdfs_on_aws) unless @activity_pdfs_on_aws.nil?
    @co_pdfs_on_aws.concat(@info_pdfs_on_aws) unless  @info_pdfs_on_aws.nil?
    @co_info = @co_info.map{ |hash| add_md5_hash(hash) } unless @co_info.nil?
    @co_party = @co_party.map{ |hash| add_md5_hash(hash) } unless @co_party.nil?
    @co_rel_info_pdf = @co_rel_info_pdf.map{ |hash| add_md5_hash(hash) } unless @co_rel_info_pdf.nil?
    @co_rel_act_pdf = @co_rel_act_pdf.map{ |hash| add_md5_hash(hash) } unless @co_rel_act_pdf.nil?
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in update_md5_hash:\n#{e.inspect}")
  end
  
  def parse_index_activity(file)
    reader = PDF::Reader.new("#{STORE_FOLDER}/#{ACTIVITY_FOLDER}/#{file}")
    content = get_content(reader)
    parse_activity(content, file)
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_idx_activity:\n#{e.inspect}")
  end
  
  def get_rel_act_pdf()
    data = []
    num_loop = @co_activities.length
    
    num_loop.times do |i|
      data << {
        'court_id'            => @court_id,
        'case_id'             => @co_activities[i]['case_id'],
        'case_activities_md5' => @co_activities[i]['md5_hash'],
        'case_pdf_on_aws_md5' => @activity_pdfs_on_aws[i]['md5_hash']
      }
    end
    data
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_rel_act_pdf:\n#{e.inspect}")
  end
  
  def parse_activity(content, file)
    hyperlink = decrypt_name(file)
    unless content.nil?
      info = parse_info(content)
      unless info.nil? | info["case_party"].nil?
        @co_info << get_info(info)
        @co_party.concat(get_activity_party(info))
        @co_activities << get_activities(info, hyperlink)
        @activity_pdfs_on_aws << get_pdfs_on_aws(info, file, "activity", hyperlink)
      end
    end
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_activity:\n#{e.inspect}")
  end
  
  def store_inside_hyperlinks(inside_hyperlinks)
    inside_hyperlinks.each do |hyperlink|
      next if hyperlink.include?("file\:\/\/\/")
      hyperlink = hyperlink.gsub("http://", "https://")
      @scraper.download_pdfs(hyperlink, ACTIVITY_FOLDER) unless hyperlink.nil?
    end
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in store_inside_hyperlinks:\n#{e.inspect}")
  end

  def parse_case(content, file)
    hyperlink = decrypt_name(file)
    add_info = parse_add_info(content)
    parse_all_case(add_info, hyperlink, file)
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_case:\n#{e.inspect}")
  end
  
  def parse_htm_case(htm, file)
    hyperlink = decrypt_name(file)
    add_info = parse_htm_add_info(htm)
    parse_all_case(add_info, hyperlink, file)
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_htm_case:\n#{e.inspect}")
  end
  
  def parse_all_case(add_info, hyperlink, file)
    virtual_add_info = get_add_info(add_info)
    @co_add_info = virtual_add_info
    @co_party.concat(get_party(add_info))
    @info_pdfs_on_aws = get_pdfs_on_aws(add_info, file, "info", hyperlink)
    virtual_add_info = virtual_add_info.map{ |hash| add_md5_hash(hash) } unless virtual_add_info.nil?
    @info_pdfs_on_aws = @info_pdfs_on_aws.map{ |hash| add_md5_hash(hash) } unless @info_pdfs_on_aws.nil?
    @co_rel_info_pdf.concat(get_rel_info_pdf(virtual_add_info, @info_pdfs_on_aws)) unless virtual_add_info.nil?
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_all_case:\n#{e.inspect}")
  end

  def get_rel_info_pdf(vir_add_info, pdfs_aws)
    num_loop = vir_add_info.length
    data = []
    num_loop.times do |i|
      data << {
        'court_id'            => @court_id,
        'case_id'             => vir_add_info[i]['case_id'],
        'case_info_md5'       => vir_add_info[i]['md5_hash'],
        'case_pdf_on_aws_md5' => pdfs_aws[i]['md5_hash']
      }
    end
    data
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_rel_info_pdf:\n#{e.inspect}")
  end
  
  def get_activities(info, hyperlink)
    activity_date = ""
    activity_date = Date.parse(info['case_filed_date']).strftime('%Y-%m-%d') unless info['case_filed_date'].nil?
    {
      "court_id"      => @court_id,
      "case_id"       => info["case_id"],
      "activity_date" => activity_date,
      "activity_desc" => nil,
      "activity_type" => "Opinion",
      "file"          => hyperlink
    }
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_activities:\n#{e.inspect}")
  end
  
  def get_info(info)
    case_filed_date = Date.parse(info['case_filed_date']).strftime('%Y-%m-%d') unless info['case_filed_date'].nil?
    {
      "court_id"              => @court_id,
      "case_id"               => info["case_id"],
      "case_name"             => info["case_name"],
      "case_filed_date"       => case_filed_date,
      "case_type"             => info["case_type"],
      "case_description"      => info["case_description"],
      "disposition_or_status" => info["disposition_or_status"],
      "status_as_of_date"     => info["status_as_of_date"],
      "judge_name"            => info["judge_name"],
      "lower_court_id"        => info["lower_court_id"],
      "lower_case_id"         => info["lower_case_id"]
    }
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_info:\n#{e.inspect}")
  end

  def get_pdfs_on_aws(items, filename, source_type, pdf_link)
    if source_type == "info"
      aws_data = []
      items.each do |item|
        aws_link = store_to_aws(
                                  "#{STORE_FOLDER}/#{INFO_FOLDER}/#{filename}",
                                  filename,
                                  pdf_link,
                                  @court_id,
                                  item['case_id'],
                                  source_type
                                )
        aws_data << {
          'court_id' => @court_id,
          'case_id'  => item['case_id'],
          'source_type' => source_type,
          'aws_link' => aws_link,
          'source_link' => pdf_link,
          'aws_html_link' => nil
        }
      end
      aws_data
    else
      aws_link = store_to_aws(
                                "#{STORE_FOLDER}/#{ACTIVITY_FOLDER}/#{filename}",
                                filename,
                                pdf_link,
                                @court_id,
                                items['case_id'],
                                source_type
                              )
      aws_data = {
        'court_id' => @court_id,
        'case_id'  => items['case_id'],
        'source_type' => source_type,
        'aws_link' => aws_link,
        'source_link' => pdf_link,
        'aws_html_link' => nil
      }
      aws_data
    end
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_pdfs_on_aws:\n#{e.inspect}")
  end
  
  def store_to_aws(pdf_file, file_name, link, court_id, case_id, state)
    state == "info" ? state = "activity" : state = "opinion"
    key_start = "us_court_cases/#{court_id}/#{case_id}/#{state}_"
    aws_link  = ''
    name = s3_name(file_name)
    
    key  = key_start + name

    File.open(pdf_file, 'rb') do |file|
      aws_link = @s3.put_file(file, key, metadata=
                                {
                                  url: link,
                                  case_id: case_id,
                                  court_id: court_id.to_s
                                }
                             )
    end
    aws_link
  end
  
  def get_activity_party(data)
    convert_data = []
    data["case_party"].each do |party|
      convert_data << {
        "court_id"          => @court_id,
        "case_id"           => data["case_id"],
        "is_lawyer"         => party["is_lawyer"],
        "party_name"        => party["party_name"],
        "party_type"        => party["party_type"],
        "party_law_firm"    => nil,
        "party_address"     => nil,
        "party_city"        => party["party_city"],
        "party_state"       => party["party_state"],
        "party_zip"         => nil,
        "party_description" => nil
      }
    end
    convert_data
  end

  def get_party(data)
    convert_data = []
    data.each do |item|
      item["case_party"].each do |party|
        convert_data << {
          "court_id"          => @court_id,
          "case_id"           => item["case_id"],
          "is_lawyer"         => party["is_lawyer"],
          "party_name"        => party["party_name"],
          "party_type"        => party["party_type"],
          "party_law_firm"    => nil,
          "party_address"     => nil,
          "party_city"        => nil,
          "party_state"       => nil,
          "party_zip"         => nil,
          "party_description" => nil
        }
      end
    end
    convert_data
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_party:\n#{e.inspect}")
  end

  def get_add_info(add_info)
    data = []
    add_info.each do |item|
      data << {
        "court_id"             => @court_id,
        "case_id"              => item["case_id"],
        "lower_court_name"     => item["lower_court_name"],
        "lower_case_id"        => item["lower_case_id"],
        "lower_judge_name"     => item["lower_judge_name"],
        "lower_judgement_date" => nil,
        "lower_link"           => nil,
        "disposition"          => nil
      }
    end
    data
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_add_info:\n#{e.inspect}")
  end
  
  def parse_info(content)
    content = content.gsub("__", " ")
    case_id = content[/No\.(.*?)\,/m, 1].squish rescue nil
    if case_id.squish.index(/ /).nil?
      case_name = content[/#{case_id}\,(.*?) \—/, 1].squish rescue nil
      case_type = content[/\—([0-9a-zA-Z—\n\;\.\,\- ]*?)\n    /, 1]
      case_type = case_type.squish unless case_type.nil?
      case_filed_date = content.squish[/SUMMARY (.*?\d{4} )/, 1]

      status_as_of_date = get_status_as_of_data(content)
      judge_name = get_judge_name(content)
      lower_case_id   = content.squish[/#{case_id[0]}(.*?) Court No(\.|.\.) (.*?)\ /m, 3]

      party_appelle   = content.squish[/#{case_id}(.*?)#{case_filed_date}(.*?Plaintiff[- ]+Appellee)/, 2]
      party_appelle   = content.squish[/#{case_id}(.*?)#{case_filed_date}(.*?Plaintiff[- ]+Appellant)/, 2] if party_appelle.nil?
      
      party_appellant = content.squish[/#{case_id}(.*?)#{party_appelle}(.*?Defendant[- ]+Appellant)/, 2]
      party_appellant = content.squish[/#{case_id}(.*?)#{party_appelle}(.*?Defendant[- ]+Appellee)/, 2] if party_appellant.nil?
      party = parse_party(party_appelle)
      party.concat(parse_party(party_appellant))
      {
        "case_id"             => case_id,
        "case_name"           => case_name,
        "case_type"           => case_type,
        "judge_name"          => judge_name,
        "lower_case_id"       => lower_case_id,
        "case_filed_date"     => case_filed_date.squish,
        "status_as_of_date"   => status_as_of_date,
        "case_party"          => party
      }
    else
      case_id = case_id.squish.split(/\ /)[1] if case_id.squish.split(/\ /)[0] == ":"
      case_id = case_id.squish.split(/\ /)[0] unless case_id.squish.split(/\ /)[0] == ":"
      case_filed_date = content.squish[/#{case_id}(.*?)Announced(.*?\d{4})/, 2]
      party_appelle   = content.squish[/#{case_id}(.*?)#{case_filed_date}(.*?Plaintiff[- ]+Appellee)/, 2]
      party_appelle   = content.squish[/#{case_id}(.*?)#{case_filed_date}(.*?Plaintiff[- ]+Appellant)/, 2] if party_appelle.nil?
      party_appelle   = content.squish[/#{case_id}(.*?)#{case_filed_date}(.*?Appellee)/, 2] if party_appelle.nil?
      party_appelle   = content.squish[/#{case_id}(.*?)#{case_filed_date}(.*?Appellant)/, 2] if party_appelle.nil?
      
      party_appellant = content.squish[/#{case_id}(.*?)#{party_appelle}(.*?Defendant[- ]+Appellant)/, 2]
      party_appellant = content.squish[/#{case_id}(.*?)#{party_appelle}(.*?Defendant[- ]+Appellee)/, 2] if party_appellant.nil?
      party_appellant = content.squish[/#{case_id}(.*?)#{party_appelle}(.*?Appellant)/, 2] if party_appellant.nil?
      party_appellant = content.squish[/#{case_id}(.*?)#{party_appelle}(.*?Appellee)/, 2] if party_appellant.nil?

      judge_name = get_judge_name(content)
      lower_case_id = content.squish[/#{case_id[0]}(.*?) Court No(\.|.\.) (.*?)\ /m, 3]
      status_as_of_date = get_status_as_of_data(content)

      party = nil
      party = parse_party(party_appelle) unless party_appelle.nil? | parse_party(party_appelle).nil?
      party.concat(parse_party(party_appellant)) unless party_appelle.nil? | parse_party(party_appellant).nil?
      {
        "case_id"           => case_id,
        "case_filed_date"   => case_filed_date.squish,
        "case_party"        => party,
        "judge_name"        => judge_name,
        "lower_case_id"     => lower_case_id,
        "status_as_of_date" => status_as_of_date
      }
    end
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_info:\n#{e.inspect}")
  end

  def split_content(content)
    content.split("\n\n").reject(&:empty?)
  end

  def get_lower_case_id(content)
    find_index = split_content(content).index{|e| e.include? 'Court of Appeals No.'}
    if split_content(content)[find_index].include? "\n\n"
      split_content(content)[find_index].split("\n").last.match(/(\d{2}[A-Z]{2}\d{4})/)[1].squish rescue nil
    else
      split_content(content)[find_index+1].match(/(\d{2}[A-Z]{2}\d{5})/)[1].squish rescue nil
    end
  end

  def get_status_as_of_data(content)
    find_index = split_content(content).index {|e| (e.include? 'Defendant-Appellant') || (e.include? 'Appellee.') || (e.include? 'Defendant-Appellant.') || (e.include? 'Intervenors-Appellees.') || (e.include? 'Respondent-Appellant.') || (e.include? 'Respondents.') || (e.include? 'Appellees.') || (e.include? 'Juvenile-Appellant.') || (e.include? 'Plaintiffs-Appellees and Cross-Appellants.')}
    status = ''
    while true
      break if split_content(content)[find_index+=1].include? 'Division'
      ss = split_content(content)[find_index].squish rescue nil
      status = status + ss
    end
    status
  end

  def get_judge_name(content)
    find_index = split_content(content).index {|e| e.include? 'Opinion by'}
    split_content(content)[find_index].squish.split('Opinion by').last.match(/(.*concur)/i)&.captures&.first&.squish
  end

  def parse_add_info(content)
    list_case_id = content.squish.scan /Court of Appeals No\. (.*?)\ /
    add_info = []
    list_case_id.each do |case_id|
      lower_court_name = content.squish[/#{case_id[0]}(.*?)No(\.|.\.)/, 1]
      lower_case_id    = content.squish[/#{case_id[0]}(.*?) Court No(\.|.\.) (.*?)\ /m, 3]
      lower_judge_name = content.squish[/#{lower_case_id} (.*? Judge)/, 1] unless lower_case_id.nil?
      party = content.squish[/#{case_id[0]}(.*?)#{lower_judge_name}(.*?Appellant)/m, 2].squish unless lower_case_id.nil?

      next if party.nil?

      if party.include?("Appellee")
        appellee_party  = party.split(/Appellee/)[0] + "Appellee"
        appellant_party = party.split(/Appellee/)[1]
      else
        appellant_party = party
        appellee_party  = content.squish[/#{case_id[0]}(.*?)#{lower_judge_name}#{appellant_party}(.*?Appellee)/m, 2]
      end
      case_party = []
      case_party << {
        "is_lawyer"  => 0,
        "party_name" => appellee_party.split(/\,(?=[^\,]*$)/)[0].gsub("v.", "").squish,
        "party_type" => appellee_party.include?("\,") ? appellee_party.split(/\,(?=[^\,]*$)/)[1].squish : nil
      }
      next if appellee_party.split(/\,(?=[^\,]*$)/)[0].gsub("v.", "").length - 255 >= 0
      case_party << {
        "is_lawyer"  => 0,
        "party_name" => appellant_party.split(/\,(?=[^\,]*$)/)[0].gsub("v.", "").squish,
        "party_type" => appellant_party.include?("\,") ? appellant_party.split(/\,(?=[^\,]*$)/)[1].squish : nil
      }
      next if appellant_party.split(/\,(?=[^\,]*$)/)[0].gsub("v.", "").length - 255 >= 0
      status_as_of_date = get_status_as_of_data(content)
      judge_name = get_judge_name(content)
      data = {
        "case_id"           => case_id[0].squish,
        "lower_court_name"  => lower_court_name.squish,
        "lower_case_id"     => lower_case_id,
        "lower_judge_name"  => lower_case_id.nil? ? nil : lower_judge_name,
        "case_party"        => case_party,
        "status_as_of_date" => status_as_of_date.nil? ? "" : status_as_of_date,
        "judge_name"        => judge_name
      }
      add_info << data
    rescue
      next
    end
    add_info
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_add_info:\n#{e.inspect}")
  end
  
  def parse_htm_add_info(htm)
    content = ""
    list_p_tags = htm.css("p.MsoNormal")
    list_p_tags = list_p_tags.map{|each_p_tag| each_p_tag.text unless each_p_tag.text.squish.nil?}
    list_p_tags.each do |each_p_tag|
      content += each_p_tag + "\n"
    end
    
    content = content.squish unless content.nil?
    list_case_id = content.scan /Court of Appeals No\. (.*?)\ /
    add_info = []
    list_case_id.each do |case_id|
      lower_court_name = content[/#{case_id[0]}(.*?)No(\.|.\.)/, 1]
      lower_case_id    = content[/#{case_id[0]}(.*?)No(\.|.\.) (.*?)\ /m, 3]
      lower_judge_name = content[/#{lower_case_id} (.*? Judge)/, 1] unless lower_case_id.nil?
      lower_judge_name = "" if lower_judge_name.length > 100
      party = content[/#{case_id[0]}(.*?)#{lower_judge_name}(.*?Appellant)/m, 2] unless lower_judge_name.length == 0
      party = content[/#{case_id[0]}(.*?)#{lower_case_id}(.*?)[A-Z]{4,}/, 2] if party.length > 255
      party = content[/#{case_id[0]}(.*?)#{lower_case_id}(.*?Appellant)/m, 2] if lower_judge_name.length == 0
      party = content[/#{case_id[0]}(.*?)#{lower_case_id}(.*?)[A-Z]{4,}/, 2] if party.length > 255

      next if party.nil?

      if party.include?("Appellee")
        appellee_party  = party.split(/Appellee/)[0] + "Appellee"
        appellant_party = party.split(/Appellee/)[1]
      else
        appellant_party = party
        appellee_party  = content[/#{case_id[0]}(.*?)#{lower_judge_name}#{appellant_party}(.*?Appellee)/m, 2]
      end

      unless party.include?("Appellant")
        appellee_party = party.split(/ v\./)[0]
        appellee_party = appellee_party[0..-2]
        appellant_party = party.split(/ v\./)[1]
      end
      
      case_party = []
      case_party << {
        "is_lawyer"  => 0,
        "party_name" => appellee_party.split(/\,(?=[^\,]*$)/)[0].gsub("v.", ""),
        "party_type" => appellee_party.include?("\,").squish ? appellee_party.split(/\,(?=[^\,]*$)/)[1].squish : nil
      }
      next if appellee_party.split(/\,(?=[^\,]*$)/)[0].gsub("v.", "").length - 255 >= 0
      case_party << {
        "is_lawyer"  => 0,
        "party_name" => appellant_party.split(/\,(?=[^\,]*$)/)[0].gsub("v.", ""),
        "party_type" => appellant_party.include?("\,").squish ? appellant_party.split(/\,(?=[^\,]*$)/)[1].squish : nil
      }
      next if appellant_party.split(/\,(?=[^\,]*$)/)[0].gsub("v.", "").length - 255 >= 0

      status_as_of_date = get_status_as_of_data(content)
      judge_name = content[/#{case_id[0]}(.*?)#{status_as_of_date}(.*?)Opinion by (.*?) [A-Z 0-9]{12,}/, 3]
      judge_name = judge_name.split(/\-/)[0] if judge_name.include?("\-")
      judge_name = judge_name.split(/NOT/)[0] if judge_name.include?("NOT")

      data = {
        "case_id"           => case_id[0],
        "lower_court_name"  => lower_court_name,
        "lower_case_id"     => lower_case_id,
        "lower_judge_name"  => lower_case_id.nil? ? nil : lower_judge_name,
        "case_party"        => case_party,
        "status_as_of_date" => status_as_of_date.nil? ? "" : status_as_of_date.split(/\ (?=[^\ ]*$)/)[0],
        "judge_name"        => judge_name
      }
      add_info << data
    rescue
      next
    end
    add_info
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_htm_add_info:\n#{e.inspect}")
  end

  def get_content(reader)
    total_page = ''
    reader.pages.each do |page|
      total_page += page.text+"\n"
    end
    total_page
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_content:\n#{e.inspect}")
  end

  def inside_pdfs(reader)
    pdf_inside_hyperlink = []
    reader.objects.each do |ref, obj|
      pdf_inside_hyperlink << obj[:A][:URI] if obj.is_a?(Hash) && obj.include?(:A)
    end
    pdf_inside_hyperlink = pdf_inside_hyperlink.uniq
    pdf_inside_hyperlink
  end
  
  def inside_pdfs_htm(htm)
    links = htm.css("p > a @href")
    links = links.uniq
    links = links.map{|link| link.to_s}
    links
  end

  def log_store_started
    last_run = @keeper.get_last_run
    if last_run.status == 'download finished'
      last_run.update(status: 'store started')
      @run_id = last_run.id
      @run_id = @keeper.create_status('store started')
      Hamster.logger.debug "store started"
    else
      Hamster.logger.debug "Cannot start store process"
      Hamster.logger.debug "Download is not finished correctly. Exiting..."
      raise "Error: Download not finished"
    end
  end
  
  def log_store_finished
    clear_folder("#{ENV['HOME']}/HarvestStorehouse/project_0594/trash/info_co_saac_case_us/")
    clear_folder("#{ENV['HOME']}/HarvestStorehouse/project_0594/trash/activity_co_saac_case_us/")
    last_run = @keeper.get_last_run
    last_run.update(status: 'store finished')
    @keeper.update_status(status: 'store finished')
    Hamster.logger.debug "store finished"
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in log_store_finished:\n#{e.inspect}")
  end
  
  def clear_folder(base_path)
    Dir.glob("#{base_path}**").each {|p| File.delete(p) if File.file?(p)}
  end

  def get_list_year(html)
    doc = Nokogiri::HTML.parse(html)
    option_css_selector = '#year > option'
    doc.css(option_css_selector)
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_list_year:\n#{e.inspect}")
  end
  
  def get_pdf_link(html)
    doc = Nokogiri::HTML.parse(html)
    pdf_link_css_selector = '#main-content > div.wrapper-full > div.center-content-left > a @href'
    doc.css(pdf_link_css_selector)
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_pdf_link:\n#{e.inspect}")
  end
  
  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    @md5_array << hash['md5_hash']
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    hash
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in add_md5_hash:\n#{e.inspect}")
  end
  
  def ecrypt_name(link)
    convert_link = link.to_s.gsub("%20.pdf", "_20.pdf")
    convert_link = convert_link.to_s.gsub("/", "__")
    convert_link = convert_link.to_s.gsub(":", "")
    convert_link = convert_link.to_s.gsub("(", "_F_")
    convert_link = convert_link.to_s.gsub(")", "_B_")
    gen_name = convert_link.to_s + "_____" + Digest::MD5.hexdigest(link).to_s + ".pdf"
    gen_name
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in ecrypt_name:\n#{e.inspect}")
  end
  
  def decrypt_name(filename)
    filename = filename.split("_____")[0]
    filename = filename.to_s.gsub("https", "https:")
    filename = filename.to_s.gsub("__", "/")
    filename = filename.to_s.gsub("_20.pdf", "%20.pdf")
    convert_link = convert_link.to_s.gsub("_F_", "(")
    convert_link = convert_link.to_s.gsub("_B_", ")")
    filename
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in decrypt_name:\n#{e.inspect}")
  end
  
  def s3_name(filename)
    filename = filename.to_s.split("_____")[1]
    filename
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in s3_name:\n#{e.inspect}")
  end

  def get_case_pdf_on_aws(pdf_aws)
    case_pdf_on_aws = []
    pdf_aws.each do |item|
      data = {
        'source_type' => 'activity',
        'source_name' => item['activity_type'],
        'source_link' => item['file'],
        'aws_html_link' => nil
      }
      case_pdf_on_aws << data
    end
    case_pdf_on_aws
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in get_case_pdf_on_aws:\n#{e.inspect}")
  end
  
  def print_all(*args, title: nil, line_feed: true)
    Hamster.logger.debug "#{"=" * 50}#{title}#{"=" * 50}" if title
    Hamster.logger.debug args
    Hamster.logger.debug "\n" if line_feed
  end
  
  def send_to_slack(message)
    Hamster.report(to: 'Robert Arnold', message: message , use: :slack)
  end

  def parse_party(content)
    list = content.split(/\,/) unless content.nil?
    party = []
    2.times do |i|
      next if list.nil?
      party_name = list[i * 2]
      party_type = list[i * 2 + 1] + list[-1]
      party << {
        "is_lawyer"   => 1,
        "party_name"  => party_name.squish,
        "party_type"  => party_type.squish,
        "party_city"  => list.length >= 7 ? list[-3].squish : "",
        "party_state" => list[-2].squish,
      }
    end
    party
  rescue StandardError => e
    Hamster.logger.error "#{e}\n#{e.full_message}}"
    send_to_slack("project_0594 error in parse_party:\n#{e.inspect}")
  end
end
