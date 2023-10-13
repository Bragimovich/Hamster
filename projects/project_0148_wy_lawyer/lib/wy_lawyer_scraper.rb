# frozen_string_literal: true

def make_md5(news_hash)
  all_values_str = ''
  columns = %i[bar_number name link law_firm_name law_firm_county state date_admitted registration_status fax_number law_firm_website]
  columns.each do |key|
    if news_hash[key].nil?
      all_values_str = all_values_str + news_hash[key.to_s].to_s
    else
      all_values_str = all_values_str + news_hash[key].to_s
    end
  end
  Digest::MD5.hexdigest all_values_str
end



class Scraper < Hamster::Scraper

  def initialize(update=0)
    super
    run_id_class = RunId.new()
    @run_id = run_id_class.run_id
    scrape_answer = gathering(update)
    if scrape_answer == 1
      deleted_for_not_equal_run_id(@run_id) if update==1
      run_id_class.finish
    end
  end

  def gathering(update)
    limit = 100
    page = 1
    peon = Peon.new(storehouse)
    file = 'last_page'

    if "#{file}.gz".in? peon.give_list() and update == 0
      page, = peon.give(file:file).split(':').map { |q| q.to_i }
    end
    cobble = Dasher.new(:using=>:cobble)
    loop do
      logger.info "Page: #{page}"
      url_main = "https://www.wyomingbar.org/for-the-public/hire-a-lawyer/membership-directory/?lastname&firstname&firm&city&state&county&sort=lastname&search=Search&showPage=#{page}"

        #page_list_lawyers = connect_to(url_main).body
        page_list_lawyers = cobble.get(url_main)

        general_lawyers_array = parse_list_lawyers(page_list_lawyers)
        bar_number_array = general_lawyers_array.map { |row| row[:bar_number] }

        #existing_bar_numbers, existing_md5_hash = [], []
        #existing_bar_numbers = get_existing_bar_numbers(bar_number_array ,@run_id) if update == 0
        existing_md5_hash = get_md5_hash(bar_number_array, @run_id)# if update == 1

        full_lawyer_array = []
        md5_hash_array = []

        general_lawyers_array.each do |lawyer_general|
          retries = 0
          begin
            page_lawyer = cobble.get(lawyer_general[:link])
            #page_lawyer = connect_to(lawyer_general[:link]).body
            peon.put content:page_lawyer, file: lawyer_general[:bar_number].to_s
            other_lawyer = parse_lawyer(page_lawyer)
          rescue => error
            retries+=1
            if retries>3
              mess = "\nError: #{lawyer_general[:link]}| #{error}"
              log mess, :red
              Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
              exit 0
            end
            retry
          end

          lawyer = lawyer_general.merge(other_lawyer)
          lawyer[:md5_hash] = make_md5(lawyer)

          if lawyer[:md5_hash].in? existing_md5_hash and update == 1
            md5_hash_array.push(lawyer[:md5_hash])
            next
          end

          lawyer[:run_id] = @run_id
          lawyer[:touched_run_id] = @run_id

          full_lawyer_array.push(lawyer)

        end
        #full_lawyer_array.each { |q| p q }
        insert_all full_lawyer_array unless full_lawyer_array.empty?
        put_new_touched_id(md5_hash_array, @run_id)
        mark_deleted(existing_md5_hash-md5_hash_array)
        return 0 if general_lawyers_array.length==0
        break if general_lawyers_array.length < limit
        peon.put(content: "#{page}:", file: file)
        page+=1
    end
    peon.put(content: "1:", file: file)
    1
  end
end