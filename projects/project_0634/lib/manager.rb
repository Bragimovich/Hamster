require_relative 'scraper'
require_relative 'parser'
require_relative 'keeper'

class Manager < Hamster::Scraper

  def initialize(**options)
    super
    @domain = 'https://www.la-fcca.org'

    @peon = Peon.new(storehouse)
    @s3 = AwsS3.new(bucket_key = :us_court, account = :us_court)

    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new

    @md5_cash_maker = {
      :la_1c_ac_case_info => MD5Hash.new(columns:%i[court_id case_id case_name case_filed_date case_type case_description disposition_or_status status_as_of_date judge_name lower_court_id lower_case_id]),
      :la_1c_ac_case_party => MD5Hash.new(columns:%i[court_id case_id is_lawyer party_name party_type party_law_firm party_address party_city party_state party_zip party_description]),
      :la_1c_ac_case_activities => MD5Hash.new(columns:%i[court_id case_id activity_date activity_desc activity_type file]),
      :la_1c_ac_case_pdfs_on_aws => MD5Hash.new(columns:%i[court_id case_id source_type aws_link source_link aws_html_link]),
      :la_1c_ac_case_relations_activity_pdf => MD5Hash.new(columns:%i[case_activities_md5 case_pdf_on_aws_md5])
    }

    store if options[:store]
    data_download if options[:download]
    remove_all if options[:help]
  end

  def data_download
    @scraper.main
  end

  def store

    hash_la_1c_ac_case_info = {
      court_id: nil,
      case_id: nil,
      case_name: nil,
      case_filed_date: nil,
      case_type: nil,
      case_description: nil,
      disposition_or_status: nil,
      status_as_of_date: nil,
      judge_name: nil,
      lower_court_id: nil,
      lower_case_id: nil
    }
    hash_la_1c_ac_case_party = {
      court_id: nil,
      case_id: nil,
      is_lawyer: nil,
      party_name: nil,
      party_type: nil,
      party_law_firm: nil,
      party_address: nil,
      party_city: nil,
      party_state: nil,
      party_zip: nil,
      party_description: nil
    }
    hash_la_1c_ac_case_activities = {
      court_id: nil,
      case_id: nil,
      activity_date: nil,
      activity_desc: nil,
      activity_type: nil,
      file: nil
    }
    hash_la_1c_ac_case_pdfs_on_aws = {
      court_id: nil,
      case_id: nil,
      source_type: nil,
      aws_link: nil,
      source_link: nil,
      aws_html_link: nil
    }
    hash_la_1c_ac_case_relations_activity_pdf = {
      case_activities_md5: nil,
      case_pdf_on_aws_md5: nil
    }

    arr_hashes = [hash_la_1c_ac_case_info, hash_la_1c_ac_case_party, hash_la_1c_ac_case_activities, hash_la_1c_ac_case_pdfs_on_aws, hash_la_1c_ac_case_relations_activity_pdf]

    arr_html_pages = @peon.give_list
    check_file = arr_html_pages.find {|f| f =~ /main_html_page_1(_\d{4}-\d{2}-\d{2}).gz/}
    parser_html = check_file ? [].push(check_file) : arr_html_pages

    (1..parser_html.length).each do |i|

      page_file_name = arr_html_pages.find {|f| check_file ? f == check_file : f =~ /#{"main_html_page_#{i}.gz"}/}

      logger.info "*************** Starting parser page of #{page_file_name} ***************"

      body_page = @peon.give(file: page_file_name)

      arr_pdf_files = @parser.get_arr_links(body_page)

      @scraper.save_pgf_files(arr_pdf_files)

      remove_wrong_pdf_files

      table = @parser.get_table_from_page(body_page)

      table.each do |row|

      hash_data = @parser.parse_row_table(row, @domain)

      aws_link = store_to_aws(hash_data)

      unless aws_link
        remove_all_pdf_files(arr_pdf_files)
        @keeper.finish
        return
      end

      hash_data[:aws_link] = aws_link

      hash_la_1c_ac_case_info = insert_hash(main_hash: hash_data, change_hash: hash_la_1c_ac_case_info, name_hash: 'la_1c_ac_case_info')

      @keeper.save_on_la_1c_ac_case_info(hash_la_1c_ac_case_info)
      # p ['hash_la_1c_ac_case_info', hash_la_1c_ac_case_info]

      hash_la_1c_ac_case_party = insert_hash(main_hash: hash_data, change_hash: hash_la_1c_ac_case_party, name_hash: 'la_1c_ac_case_party')

      (0..hash_data[:party_name].length - 1).each do |i|
        hash_la_1c_ac_case_party[:party_name] = hash_data[:party_name][i]
        hash_la_1c_ac_case_party[:party_type] = "party_#{i + 1}"
        hash_la_1c_ac_case_party[:md5_hash] = @md5_cash_maker[:la_1c_ac_case_party].generate(hash_la_1c_ac_case_party)
        # p ['hash_la_1c_ac_case_party', hash_la_1c_ac_case_party]
        @keeper.save_on_la_1c_ac_case_party(hash_la_1c_ac_case_party)
      end

      hash_la_1c_ac_case_activities = insert_hash(main_hash: hash_data, change_hash: hash_la_1c_ac_case_activities, name_hash: 'la_1c_ac_case_activities')
      @keeper.save_on_la_1c_ac_case_activities(hash_la_1c_ac_case_activities)
      # p ['hash_la_1c_ac_case_activities', hash_la_1c_ac_case_activities]
      #
      hash_la_1c_ac_case_pdfs_on_aws = insert_hash(main_hash: hash_data, change_hash: hash_la_1c_ac_case_pdfs_on_aws, name_hash: 'la_1c_ac_case_pdfs_on_aws')
      @keeper.save_on_la_1c_ac_case_pdfs_on_aws(hash_la_1c_ac_case_pdfs_on_aws)
      # p ['hash_la_1c_ac_case_pdfs_on_aws', hash_la_1c_ac_case_pdfs_on_aws]
      #
      hash_la_1c_ac_case_relations_activity_pdf[:case_activities_md5] = hash_la_1c_ac_case_activities[:md5_hash]
      hash_la_1c_ac_case_relations_activity_pdf[:case_pdf_on_aws_md5] = hash_la_1c_ac_case_pdfs_on_aws[:md5_hash]
      @keeper.save_on_la_1c_ac_case_relations_activity_pdf(hash_la_1c_ac_case_relations_activity_pdf)
      # p ['hash_la_1c_ac_case_relations_activity_pdf', hash_la_1c_ac_case_relations_activity_pdf]
      arr_hashes.each { |hash| hash.transform_values! {|v| nil} }
      # break
      end

      remove_all_pdf_files(arr_pdf_files)

      # break
    end
    @keeper.finish
  end

  def store_to_aws(hash_data)
    pdf_storage_path = "#{storehouse}store/#{hash_data[:file_name]}"
    logger.info "*************** AWS status: find_files_in_s3 IS EMPTY  - #{@s3.find_files_in_s3(hash_data[:key]).empty?} ***************"
    if @s3.find_files_in_s3(hash_data[:key]).empty?
      if File.file?(pdf_storage_path)
        file = File.open(pdf_storage_path)
      end
      aws_link = @s3.put_file(file, hash_data[:key], metadata = {})
      file.close
    end
    return aws_link
  end

  def insert_hash(main_hash:, change_hash:, name_hash:)
    main_hash.each do |key, value|
      if change_hash.has_key?(key)
        change_hash[key] = value
      end
    end
    change_hash[:md5_hash] = @md5_cash_maker[name_hash.to_sym].generate(change_hash)
    change_hash
  end

  def remove_wrong_pdf_files
    check_duplicates = {}
    Dir.foreach("#{storehouse}/store") do |file_name|
      if file_name =~ /\.pdf_\d+$/
        original_name = file_name.sub(/_\d+$/, '')
        check_duplicates[original_name] ||= []
        check_duplicates[original_name].push(file_name)
      end
    end

    check_duplicates.each_key { |key|
      last_duplicate = check_duplicates[key].max_by { |f| f}

      check_duplicates[key].each {|file_name|
        if File.exist?("#{storehouse}/store/#{key}")
          logger.info "Deleting original file #{key}"
          File.delete("#{storehouse}/store/#{key}")
        end
        if file_name != last_duplicate
          logger.info "Deleting duplicate file  #{file_name}"
          File.delete("#{storehouse}/store/#{file_name}")
        end
      }
      File.rename("#{storehouse}/store/#{last_duplicate}", "#{storehouse}/store/#{last_duplicate.sub(/_\d+$/, '')}")
    }
  end

  def remove_all_pdf_files(arr_pdf_files)
    arr_pdf_files.each { |pdf_file|
      begin
        FileUtils.mv("#{storehouse}store/#{pdf_file[24..]}", "#{storehouse}trash/")
      rescue Exception => e
        logger.error "caught exception #{e}"
      ensure
        next
      end
    }
    @peon.throw_temps()
  end

end

