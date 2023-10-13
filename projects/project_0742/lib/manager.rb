# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper = Scraper.new
  end

  def download
    download_files('https://apps.elections.virginia.gov/SBE_CSV/CF/','Contributions')
    download_files('https://apps.elections.virginia.gov/SBE_CSV/StatementsOfOrganization/','Committees')
  end

  def store
    cont_url = 'https://apps.elections.virginia.gov/SBE_CSV/CF/'
    com_url = 'https://apps.elections.virginia.gov/SBE_CSV/StatementsOfOrganization/'
    store_data('Contributions',VaRawReport,'report',cont_url)
    store_data('Contributions',VaRawScheduleA,'schedulea',cont_url)
    store_data('Contributions',VaRawScheduleB,'scheduleb',cont_url)
    store_data('Contributions',VaRawScheduleC,'schedulec',cont_url)
    store_data('Contributions',VaRawScheduleD,'scheduled',cont_url)
    store_data('Contributions',VaRawScheduleE,'schedulee',cont_url)
    store_data('Contributions',VaRawScheduleF,'schedulef',cont_url)
    store_data('Contributions',VaRawScheduleG,'scheduleg',cont_url)
    store_data('Contributions',VaRawScheduleH,'scheduleh',cont_url)
    store_data('Contributions',VaRawScheduleI,'schedulei',cont_url)
    store_data('Committees',VaRawCandidate,'candidate',com_url)
    store_data('Committees',VaRawFedral,'federal',com_url)
    store_data('Committees',VaRawInaugural,'inaugural',com_url)
    store_data('Committees',VaRawOutState,'outofstate',com_url)
    store_data('Committees',VaRawParty,'party',com_url)
    store_data('Committees',VaRawReferendum,'referendum',com_url)
    store_data('Committees',VaRawPolitical,'politicalaction',com_url)
    File.delete("#{storehouse}store/#{@keeper.run_id}/links.txt")
    FileUtils.rm_rf("#{storehouse}store/#{@keeper.run_id}")
    @keeper.finish
  end

  private

  def download_files(main_url,type)
    downloaded_folders = get_downloaded_folders(type)
    main_response = @scraper.get_main_page(main_url)
    years_links = @parser.get_years(main_response.body)
    years_links.each do |year_link|
      next if downloaded_folders.include? year_link.split('/').last
      inner_response = @scraper.get_inner_page(year_link)
      csv_links = @parser.get_csv_links(inner_response.body)
      csv_links.each do |csv_link|
        csv_response = @scraper.get_inner_page(csv_link)
        file_name = csv_link.split('/').last.gsub('.csv','')
        subfolder = "#{type}/#{year_link.split('/').last}/"
        save_file(csv_response.body,file_name,subfolder,'csv')
      end
    end
  end

  def store_data(folder,model,key,data_source_url)
    files = get_files(folder,'*.csv').select{|e| e.downcase.include? key}
    files = files.reject{|e| (e.downcase.include? 'federal') || (e.downcase.include? 'outofstate')} if (key == 'politicalaction')
    processed_files = file_handling(processed_files,'r') rescue []
    files.each do |file|
      next if processed_files.include? file
      data_array,md5_array = @parser.parse_data(file,@keeper.run_id,data_source_url)
      @keeper.insert_records(data_array,model)
      @keeper.update_touch_run_id(md5_array,model)
      @keeper.mark_delete(model)
      file_handling(file,'a')
    end
  end

  def file_handling(content,flag)
    list = []
    File.open("#{storehouse}store/#{@keeper.run_id}/links.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

  def get_files(folder, file_type)
    Dir["#{storehouse}store/#{@keeper.run_id}/#{folder}/**/#{file_type}"]
  end

  def get_downloaded_folders(folder)
    peon.list(subfolder: "#{@keeper.run_id}/#{folder}").sort[0...-1] rescue []
  end

  def save_file(content,file_name,path,extension)
    FileUtils.mkdir_p "#{storehouse}store/#{@keeper.run_id}/#{path}"
    file_storage_path = "#{storehouse}store/#{@keeper.run_id}/#{path}/#{file_name}.#{extension}"
    File.open(file_storage_path, "wb") do |f|
      f.write(content)
    end
  end

end