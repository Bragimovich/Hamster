# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'fileutils'

require_relative 'manager'

class Scraper < Hamster::Scraper
  MAX_RETRY_COUNT = 50
    PATH = "/home/hamster/HarvestStorehouse/project_0324/"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def csv_download_get_request
    file_path = "#{PATH}store/connecticut_prof_license_#{Time.now.strftime('%Y%m%d')}.csv"

    headers = {
        'accept_language' => 'en-US,en;q=0.5',
        'connection' => 'keep-alive',
        'upgrade_insecure_requests' => '1',
        'Dnt' => '1'
    }

    response = connect_to(url: 'https://data.ct.gov/api/views/ngch-56tr/rows.csv?accessType=DOWNLOAD',
                          headers: headers,
                          method: :get_file,
                          filename: file_path,
                          proxy_filter: @proxy_filter)
    Hamster.logger.debug "CSV DOWNLOADED"
    { resp: response, file_path: file_path }
  end

  def prepare_csv_to_upload(file_path, batch_size = 1000)
    new_file_path = "#{file_path.gsub('.csv', '')}_prepared.csv"

    File.open(new_file_path, 'w') do |f|
      File.foreach(file_path).each_slice(batch_size) do |batch|
        batch.each do |line|
          line = line.gsub('\\,', ',')
          f.puts(line) unless line.empty?
        end
        #sleep(0.0005) # Adjust the duration of the sleep as needed
      end
    end

    new_file_path
  end

  def remove_prepared_csv_file(file_path)
    File.delete(file_path) if File.exist?(file_path)
  end

  def move_file_to_trash(file_path)
    filename = file_path.split('/').last
    trash_file_path = "#{storehouse}trash/#{filename}"
    FileUtils.mv(file_path, trash_file_path)
    trash_file_path
  end

  def file_to_tar(file_path)
    filename = file_path.split('/').last.gsub('.csv', '')
    file_dir = file_path.split('/')[0...-1].join('/')

    system("cd #{file_dir} && tar -cf /home/hamster/HarvestStorehouse/project_0324/trash/#{filename}__#{Time.now.strftime("%Y-%m-%d")}.tar #{filename}.csv")
    system("test -f /home/hamster/HarvestStorehouse/project_0324/trash/#{filename}__#{Time.now.strftime("%Y-%m-%d")}.tar && find #{file_path} -delete")
    "/home/hamster/HarvestStorehouse/project_0324/trash/#{filename}__#{Time.now.strftime("%Y-%m-%d")}.tar"
  end

  private

  def send_request(uri, request)
    retry_count = 0

    begin
      proxy             = Camouflage.new(local_chrome: false )
      current_proxy     = proxy.swap
      current_proxy_uri = proxy.uri(current_proxy)
      proxy_username    = current_proxy_uri[:username]
      proxy_password    = current_proxy_uri[:password]
      proxy_host        = current_proxy_uri[:host]
      proxy_port        = current_proxy_uri[:port]

      req_options = {
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE
      }

      TCPSocket.socks_username = proxy_username
      TCPSocket.socks_password = proxy_password

      response = Net::HTTP.SOCKSProxy(proxy_host, proxy_port).start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      Hamster.logger.debug "RESPONSE" * 100
      Hamster.logger.debug response
      Hamster.logger.debug response.body
      Hamster.logger.debug "END RESPONSE" * 100

      return response if response.is_a? Net::HTTPInternalServerError
      raise 'Response is not NET::HTTPOK' unless response.is_a? Net::HTTPOK

      response
    rescue StandardError => e
      Hamster.logger.debug e
      Hamster.logger.debug e.backtrace

      retry_count += 1
      retry if retry_count <= MAX_RETRY_COUNT
      raise 'Send request MAX_RETRY_COUNT reached'
    end
  end

  # Move this method to public methods when docker will support AWS.
  def upload_file_to_aws(file_path)
    Hamster.logger.debug "START_UPLOAD_FILE_TO_AWS"
    Hamster.logger.debug file_path
    Hamster.logger.debug system("aws s3 cp #{file_path} s3://hamster-storage1/tasks/scrape_tasks/st0324/")
    Hamster.logger.debug system("aws s3 ls s3://hamster-storage1/tasks/scrape_tasks/st0324/`")
  end

end
