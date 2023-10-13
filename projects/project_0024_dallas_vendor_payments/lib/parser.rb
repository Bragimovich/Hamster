# frozen_string_literal: true

require_relative '../models/irs_nonprofit_runs'
require_relative '../models/irs_nonprofit_orgs'
require_relative '../models/irs_nonprofit_temp_forms'
require_relative '../models/irs_nonprofit_forms_pub_78'
require_relative '../models/irs_nonprofit_forms_auto_rev_list'
require_relative '../models/irs_nonprofit_forms_990n'
require_relative '../models/irs_nonprofit_forms_990_series'

require_relative '../lib/validate_error.rb'

class Parser < Hamster::Harvester

  def initialize
    super

    @full_parse = commands[:full_parse]
    @orgs_parse = commands[:parse_orgs_only] || @full_parse
    @all_forms = commands[:parse_all_forms]
    @pub_78 = commands[:parse_pub_78] || @all_forms || @full_parse
    @auto_rev_list = commands[:parse_auto_rev_list] || @all_forms || @full_parse
    @form_990n = commands[:parse_form_990n] || @all_forms || @full_parse
    @form_990s = commands[:parse_form_990_series] || @all_forms || @full_parse


    run = IrsNonprofitRuns.all.to_a.last
    @run_id = run && %w(processing error pause scraped).include?(run[:status]) ? run[:id] : (commands[:run_id] || raise(ValidateError, 'No active or scraped scrapings.'))

    @pages_folders = []

    get_folders

    @tries = 0

    @start_time = Time.now
  end

  def main
    parse_pub_78 if @pub_78
    parse_auto_rev_list if @auto_rev_list
    parse_form_990n if @form_990n
    parse_form_990s if @form_990s

    while check_time && !no_pages_left?
      get_folders
      @pages_folders.each do |folder|
        break unless check_time

        @semaphore = Mutex.new

        list = @_peon_.give_list(subfolder: folder)

        ​threads = Array.new(commands[:threads] || 1) do
          Thread.new do
            t_files = []
            @semaphore.synchronize {
              t_files = list.pop(10)
            }
            break if t_files.size.zero? && list.count.zero?

            t_files.each do |file_name|
              file = @_peon_.give(file: file_name, subfolder: folder)

              break unless file.is_a? String
              Nokogiri::HTML.parse(file).css('ul.views-row li').each do |row|
                ein = row.at('.search-excerpt span:first-child').text[/\d+-\d+/].delete('-')
                org_name = row.at('.result-orgname a').text.strip
                org_link = row.at('.result-orgname a')['href']
                org_parens = row.at('.result-orgname i') ? row.at('.result-orgname i').text.strip[1..-2].strip : nil
                org_state = row.at('.search-excerpt span:nth-child(3)').text.delete(',').strip
                org_city = row.at('.search-excerpt span:nth-child(2)').text.delete(',').strip

                h = {
                    ein: ein,
                    org_name: org_name,
                    org_name_parens: org_parens,
                    state: org_state,
                    city: org_city,
                    org_link: org_link
                }

                new_md5 = Digest::MD5.hexdigest(h.to_s)

                begin
                  check = Covid19Vaccination.where("ein = #{ein} AND deleted != 1").as_json.first

                  if check && check['md5_hash'] == new_md5
                    Covid19Vaccination.update(check['id'], touched_run_id: @run_id)
                  elsif check
                    Covid19Vaccination.update(check['id'], deleted: true)
                    Covid19Vaccination.insert_ignore_into(h.merge({run_id: @run_id, touched_run_id: @run_id, md5_hash: new_md5}))
                  else
                    Covid19Vaccination.insert_ignore_into(h.merge({run_id: @run_id, touched_run_id: @run_id, md5_hash: new_md5}))
                  end
                ensure
                  Covid19Vaccination.clear_active_connections!
                end
              end

              @_peon_.move(file: file_name, from: folder, to: folder)
            end
          end
        end

        ​threads.each(&:join)
      end
    end
  rescue ValidateError => e
    p e.message
  rescue => e
    p e.backtrace
    p e.message
  else
    run = IrsNonprofitRuns.all.to_a.last
    if @run_id && run && run[:status] == 'scraped' && no_pages_left?
      IrsNonprofitRuns.update(@run_id, {status: 'finished'})
      Covid19Vaccination.where("touched_run_id != ?", @run_id).update_all(deleted: true)
    end
  end

  def process_page(page)

  end

  def parse_pub_78
    raw = IrsNonprofitTempForms.get_pub_78(1000)

    while raw.size > 0
      raw.map.with_index {|r, i| raw[i]['deductibility_code'] = r['deductibility_code'].strip}

      IrsNonprofitFormsPub78.insert_all(raw)
      IrsNonprofitTempForms.delete_pub_78(raw)
      raw = IrsNonprofitTempForms.get_pub_78(1000)
    end

    run = IrsNonprofitRuns.all.to_a.last
    IrsNonprofitTempForms.connection.drop_table(:irs_nonprofit_pub_78_temp, if_exists: true) if run && run[:status] == 'scraped'
  end

  def parse_auto_rev_list
    raw = IrsNonprofitTempForms.get_auto_rev_list(1000)

    exemption_types = {
        '2' => '501(c)(2)',
        '3' => '501(c)(3)',
        '4' => '501(c)(4)',
        '5' => '501(c)(5)',
        '6' => '501(c)(6)',
        '7' => '501(c)(7)',
        '8' => '501(c)(8)',
        '9' => '501(c)(9)',
        '10' => '501(c)(10)',
        '11' => '501(c)(11)',
        '12' => '501(c)(12)',
        '13' => '501(c)(13)',
        '14' => '501(c)(14)',
        '15' => '501(c)(15)',
        '16' => '501(c)(16)',
        '17' => '501(c)(17)',
        '18' => '501(c)(18)',
        '19' => '501(c)(19)',
        '20' => '501(c)(20)',
        '21' => '501(c)(21)',
        '22' => '501(c)(22)',
        '23' => '501(c)(23)',
        '24' => '501(c)(24)',
        '25' => '501(c)(25)',
        '26' => '501(c)(26)',
        '27' => '501(c)(27)',
        '28' => '501(c)(28)',
        '29' => '501(c)(29)',
        '40' => '501(d)',
        '50' => '501(e)',
        '60' => '501(f)',
        '70' => '501(k)',
        '71' => '501(n)',
        '80' => '521(a)',
        '82' => '527',
        '0' => '00',
        '1' => '501(c)(1)',
        '90' => '501(c)(90)'
    }

    while raw.size > 0
      data = []
      raw.each do |r|
        data << {
            ein: r['ein'],
            exemption_type_raw: r['exemption_type'],
            exemption_type_clean: exemption_types[r['exemption_type'].to_i.to_s],
            revocation_date: Date.parse(r['revocation_date']).to_s,
            revocation_posting_date: Date.parse(r['revocation_posting_date']).to_s,
            exemption_reinstatement_date: r['exemption_reinstatement_date'] =~ /\d+-\w+-\d+/ ? Date.parse(r['exemption_reinstatement_date'].to_s).to_s : nil
        }
      end

      IrsNonprofitFormsAutoRevList.insert_all(data)
      IrsNonprofitTempForms.delete_auto_rev_list(raw)
      raw = IrsNonprofitTempForms.get_auto_rev_list(1000)
    end

    run = IrsNonprofitRuns.all.to_a.last
    IrsNonprofitTempForms.connection.drop_table(:irs_nonprofit_auto_rev_list_temp, if_exists: true) if run && run[:status] == 'scraped'
  end

  def parse_form_990n
    raw = IrsNonprofitTempForms.get_990n(1000)

    while raw.size > 0
      data = []
      raw.each do |r|

        begin
          data << {
              ein: r['ein'],
              organization_terminated: r['f_col'] == 'T',
              tax_period: r['tax_period_year'],
              tax_period_start: Date.strptime(r['tax_period_start'], '%m-%d-%Y').to_s,
              tax_period_end: Date.strptime(r['tax_period_end'], '%m-%d-%Y').to_s,
              principal_officer_name: r['principal_officer_name'],
              principal_officer_street: r['principal_officer_street'],
              principal_officer_city: r['principal_officer_city'],
              principal_officer_state: r['principal_officer_state'],
              principal_officer_zip: r['principal_officer_zip'],
              mailing_address_street: r['mailing_address_street'],
              mailing_address_city: r['mailing_address_city'],
              mailing_address_state: r['mailing_address_state'],
              mailing_address_zip: r['mailing_address_zip'],
              website_url: r['website_url']
          }
        rescue
          p r['tax_period_start'], r['tax_period_end']
        end

      end

      IrsNonprofitForms990n.insert_all(data)
      IrsNonprofitTempForms.delete_990n(raw)
      raw = IrsNonprofitTempForms.get_990n(1000)
    end

    run = IrsNonprofitRuns.all.to_a.last
    IrsNonprofitTempForms.connection.drop_table(:irs_nonprofit_990n_temp, if_exists: true) if run && run[:status] == 'scraped'
  end

  def parse_form_990s
    raw = IrsNonprofitTempForms.get_990s(1000)

    while raw.size > 0
      data = []
      raw.each do |r|

        begin
          data << {
              ein: ('0' + r['ein'])[-9..-1],
              filing_type: r['filing_type'],
              tax_period: r['tax_period'],
              return_fill_date: Date.strptime(r['return_fill_date'], '%m/%d/%Y').to_s,
              return_type: r['return_type'],
              return_pdf_link: "https://apps.irs.gov/pub/epostcard/cor/#{r['ein']}_#{r['tax_period']}_#{r['return_type']}_#{Date.strptime(r['return_fill_date'], '%m/%d/%Y').to_s.delete('-')}#{r['return_link_id']}.pdf"
          }
        end

      end

      IrsNonprofitForms990Series.insert_all(data)
      IrsNonprofitTempForms.delete_990s(raw)
      raw = IrsNonprofitTempForms.get_990s(1000)
    end

    run = IrsNonprofitRuns.all.to_a.last
    IrsNonprofitTempForms.connection.drop_table(:irs_nonprofit_990s_temp, if_exists: true) if run && run[:status] == 'scraped'
  end


  # def parse_org_pages
  #   sleep 5
  #   while (!@scraping && get_raw_org_page) || @scraping
  #     try(get_raw_org_page, 10, 1, 1) if @scraping
  #     puts get_raw_org_page
  #     page = basename(get_raw_org_page)
  #     move_file('raw_org_pages', page, 'org_pages_archive')
  #     page = Nokogiri::HTML.parse(read_from_gz('org_pages_archive', page))
  #
  #     puts normalize_string(page.at_css('h1.pup-search-detail-capitalize-text').text)
  #     puts normalize_string(page.at_css('span.pup-page-site-index-sub-title.pup-search-detail-capitalize-text').text)
  #   end
  # end
  #
  # def get_raw_org_page
  #   Find.find(create_dir('raw_org_pages')).grep(/.*\d\.gz/).first
  # end
  #
  # def try(something, times, time_break, step)
  #   if something
  #     true
  #   elsif times > 0
  #     sleep(time_break)
  #     try(something, times - 1, time_break*step, step)
  #   else
  #     false
  #   end
  # end

  private

  def get_folders
    @pages_folders = Dir["#{storehouse}store/orgs_list_pages/*/"].map {|s| s.gsub("#{storehouse}store/", '')}
  end

  def no_pages_left?
    Dir["#{storehouse}store/orgs_list_pages/*/*.gz"].size.zero?
  end

  def check_time
    (Time.now - @start_time) / 60 < 50
  end
end
