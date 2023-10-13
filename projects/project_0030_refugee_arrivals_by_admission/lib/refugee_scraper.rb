# frozen_string_literal: true

class RefugeeScraper < Hamster::Scraper
  SOURCE = 'https://www.wrapsnet.org/'
  
  def initialize
    super
  end
  
  def download
    headers = {
      accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      accept_encoding:           'gzip, deflate, br',
      accept_language:           'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
      cache_control:             'no-cache',
      pragma:                    'no-cache',
      sec_fetch_dest:            'document',
      sec_fetch_mode:            'navigate',
      sec_fetch_site:            'same-origin',
      sec_fetch_user:            '?1',
      upgrade_insecure_requests: '1'
    }
    filter  = ProxyFilter.new(duration: 3.hours, touches: 1000)
    source  = connect_to(SOURCE + 'admissions-and-arrivals/', headers: headers, proxy_filter: filter)
    parser  = RefugeeParser.new(source&.body)
    link    = parser.pdf_link
    
    headers = {
      accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      accept_encoding:           'gzip, deflate, br',
      accept_language:           'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
      cache_control:             'max-age=0',
      if_modified_since:         'Wed, 03 Feb 2021 17:57:36 GMT',
      if_none_match:             '"601ae410-32885"',
      sec_fetch_dest:            'document',
      sec_fetch_mode:            'navigate',
      sec_fetch_site:            'none',
      sec_fetch_user:            '?1',
      upgrade_insecure_requests: '1'
    }
    puts "#{link}".light_white
    
    filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    
    resp = connect_to(URI.encode(SOURCE + link.gsub(%r{^/}, '')), headers: headers, proxy_filter: filter) do |response|
      puts "#{response.body.size}".light_white
      res = response.headers[:content_type]&.match?(%r{pdf}) && response.body.size.positive?
      puts "#{res.inspect}".light_white
      res
    end
    puts "#{resp.inspect}".light_white
    file = resp&.body
    open("#{storehouse}/store/1111.pdf", 'wb') { |f| f.write(file) }
  end
  
  def store
    runs = RPCRefugeeArrivalsByAdmissionCategoryRun
    unless runs.last&.status == 'processing'
      runs.create!(status: 'processing')
    end
    current_run = runs.last
    
    dataset        = RPCRefugeeArrivalsByAdmissionCategory
    existing_rows  = dataset.where(deleted: false)
    first_run      = existing_rows.empty?
    processing_pdf = 'gs -dCompatiblityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile='
    pdf_raw        = "#{storehouse}/store/1111.pdf"
    pdf_processed  = "#{storehouse}store/done.pdf"
    
    system "#{processing_pdf}#{pdf_processed} #{pdf_raw} > /dev/null"
    
    doc              = RefugeeParser.new(pdf_processed, :pdf)
    doc.table_marker = /Admission.+Grand Total/
    
    doc.pdf_table.each do |row|
      if first_run
        row[:md5_hash] = Digest::MD5.hexdigest row.values.join('')
        data           = dataset.flail { |k| [k, row[k]] }
        
        if first_run
          data[:run_id]         = current_run.id
          data[:touched_run_id] = current_run.id
          dataset.store(data)
          
          next
        end
      
      end
    
    end
    
    dataset.where(deleted: false).where.not(touched_run_id: current_run.id).update_all(deleted: true)
    runs.find_by(id: current_run.id).update(status: 'done')
  end
  
  private
  
  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end
    
    response
  end

end
