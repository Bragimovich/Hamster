# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
  end

  def download(type)
    @type = type
    count = 0
    filer_ids = file_handling(filer_ids, 'r', 'ids') rescue []
    save_value = filer_ids.map{ |e| e.split('_').last.to_i }.sort.last
    save_value = 0 if (save_value.nil?)
    downloaded_ids = filer_ids.map{ |e| e.split('_').first } rescue []
    main_response = scraper.get_main_page_response
    cookie_value = main_response.headers['set-cookie']
    event_val, view_state, view_state_gen = parser.get_form_values(main_response.body)
    search_page_response = scraper.get_search_page_response(event_val, view_state, view_state_gen, cookie_value)
    result_page_response = scraper.get_result_page_response(cookie_value)
    ctl_values,total_page = parser.get_ctl_values_and_page_count(result_page_response.body)
    event_val, view_state, view_state_gen = parser.get_form_values(result_page_response.body)
    while true
      break if ((type == 'first') && (count == total_page / 2))
      break if ((type == 'second') && (count > total_page))
      pagination_response = scraper.pagination_post_request(view_state, view_state_gen, cookie_value)
      if ((type == 'first') || ((type == 'second') && (count >= total_page / 2)))
        ctl_values.each do |ctl_value|
          post_response = scraper.candidate_inner_page_post(view_state, view_state_gen, cookie_value, ctl_value)
          filer_id = post_response.headers['location'].split('=').last
          next if (downloaded_ids.include? filer_id)
          pdf_page_response = scraper.get_view_filer_page(filer_id, cookie_value)
          download_contribution_file(pdf_page_response, cookie_value, filer_id, save_value)
          download_expenditure_file(pdf_page_response, cookie_value, filer_id, save_value)
          pdf_ids = parser.get_pdf_ids(pdf_page_response.body)
          pdf_ids.each do |pdf_id|
            response = scraper.pdf_post_request(pdf_id, cookie_value)
            pdf_download_id = response.headers['location'].split('/').last
            final_response = scraper.download_pdf(pdf_download_id, cookie_value)
            saving_file(final_response.body, "#{pdf_id}", "#{type}/#{filer_id}_#{save_value}/", 'pdf')
          end
          file_handling("#{filer_id}_#{save_value}", 'a', 'ids')
          save_value += 1
        end
      end
      ctl_values,total_page = parser.get_ctl_values_and_page_count(pagination_response.body)
      event_val, view_state, view_state_gen = parser.get_form_values(pagination_response.body)
      count += 1
      if ((type == 'first') || ((type == 'second') && (count > total_page / 2)))
        store
        FileUtils.rm_rf("#{storehouse}store/#{keeper.run_id}/#{type}")
      end
      main_response = scraper.get_main_page_response
      cookie_value = main_response.headers['set-cookie']
    end
    file_handling("#{type}", 'a', 'status')
    finish_status = file_handling(finish_status, 'r', 'status') rescue []
    if (finish_status.count == 2)
      keeper.finish
      FileUtils.rm_rf("#{storehouse}store/#{keeper.run_id}")
    end
  end

  def store
    store_contribution_data
    store_expenditure_data
    update_pdfs
    store_candidate_committee_pac_data
    model_keys = ['la_cont','la_exp','la_can','la_com','la_pac']
    model_keys.each do |key|
      keeper.mark_delete(key)
    end
  end

 private

 attr_accessor :keeper, :parser, :scraper, :type

 def download_contribution_file(pdf_page_response, cookie_value, filer_id, count)
  event_val, view_state, view_state_gen = parser.get_form_values(pdf_page_response.body)
  post_response = scraper.get_post_view_filer_page_cont(event_val, view_state, view_state_gen, filer_id, cookie_value)
  scraper.get_contribution_load_page(cookie_value)
  scraper.get_wait_page(cookie_value)
  scraper.get_contribution_redirect_page(cookie_value)
  result_page_response = scraper.get_contribution_result_page(cookie_value)
  event_val, view_state, view_state_gen = parser.get_form_values(result_page_response.body)
  csv_response = scraper.download_contribution_csv(event_val, view_state, view_state_gen, cookie_value)
  saving_file(csv_response.body, "cont", "#{type}/#{filer_id}_#{count}/", 'csv')
 end

 def download_expenditure_file(pdf_page_response, cookie_value, filer_id, count)
  event_val, view_state, view_state_gen = parser.get_form_values(pdf_page_response.body)
  post_response = scraper.get_post_view_filer_page_exp(event_val, view_state, view_state_gen, filer_id, cookie_value)
  scraper.get_expenditure_load_page(cookie_value)
  scraper.get_wait_page(cookie_value)
  scraper.get_expenditure_redirect_page(cookie_value)
  result_page_response = scraper.get_expenditure_result_page(cookie_value)
  event_val, view_state, view_state_gen = parser.get_form_values(result_page_response.body)
  csv_response = scraper.download_expenditure_csv(event_val, view_state, view_state_gen, cookie_value)
  saving_file(csv_response.body, "exp", "#{type}/#{filer_id}_#{count}/", 'csv')
 end

  def store_contribution_data
    files = get_files("#{keeper.run_id}/#{type}", '*.csv').select{ |e| e.include? 'cont' }
    files.each do |file|
      filer_id = file.split('/')[-2].split('_').first
      data_array,md5_array = parser.parse_contribution_data(file, keeper.run_id, filer_id)
      keeper.insert_records(data_array, 'la_cont')
      keeper.update_touched_run_id(md5_array, 'la_cont')
    end
  end

  def store_expenditure_data
    files = get_files("#{keeper.run_id}/#{type}", '*.csv').select{ |e| e.include? 'exp' }
    files.each do |file|
      filer_id = file.split('/')[-2].split('_').first
      data_array,md5_array = parser.parse_expenditure_data(file, keeper.run_id, filer_id)
      keeper.insert_records(data_array, 'la_exp')
      keeper.update_touched_run_id(md5_array, 'la_exp')
    end
  end

  def store_candidate_committee_pac_data
    files = get_files("#{keeper.run_id}/#{type}", '*.pdf').select{ |e| e.include? 'updated' }
    files.each do |file|
      report_number = file.split('/').last.gsub('.pdf','').split('_').last
      filer_id = file.split('/')[-2].split('_').first
      flag = parser.read_pdf(file)
      if (flag)
        candidate_data,can_md5 = parser.parse_candidates_data(report_number, filer_id, keeper.run_id)
        candidate_data = [] if ((candidate_data.first.nil?) || (candidate_data.first[:candidate_name].nil?))
        committee_data,com_md5 = parser.parse_committee_data(report_number, filer_id, keeper.run_id)
        committee_data = [] if ((committee_data.first.nil?) || (committee_data.first[:committee_name].nil?))
        pac_data,pac_md5 = parser.parse_pac_data(report_number, filer_id, keeper.run_id)
        pac_data = pac_data.reject{ |e| e.empty? }
        keeper.insert_records(candidate_data, 'la_can')
        keeper.insert_records(committee_data, 'la_com')
        keeper.insert_records(pac_data, 'la_pac')
        keeper.update_touched_run_id(can_md5, 'la_can')
        keeper.update_touched_run_id(com_md5, 'la_com')
        keeper.update_touched_run_id(pac_md5, 'la_pac')
      end
    end
  end

  def get_files(folder, file_type)
    Dir["#{storehouse}store/#{folder}/**/#{file_type}"]
  end

  def update_pdfs
    files = get_files("#{keeper.run_id}", '*.pdf').reject{ |e| e.include? 'updated' }
    files.each do |file|
      content = parser.get_content(file)
      file_name = "updated_#{file.split('/').last.gsub('.pdf','')}"
      saving_file(content, file_name, "#{file.split('/')[-3..-2].join('/')}", 'pdf')
    end
  end

  def saving_file(content, file_name, path, type)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}/#{path}/"
    file_storage_path = "#{storehouse}store/#{keeper.run_id}/#{path}/#{file_name}.#{type}"
    File.open(file_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def file_handling(content, flag, file_name)
    list = []
    File.open("#{storehouse}store/#{@keeper.run_id}/#{file_name}.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

end
