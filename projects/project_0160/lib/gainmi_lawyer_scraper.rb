# frozen_string_literal: true

def make_md5(news_hash)
  all_values_str = ''
  columns = %i[bar_number name link law_firm_name law_firm_state date_admitted registration_status]
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

  DB_MODELS = {:georgia => GeorgiaLawyerStatus, :indiana => IndianaLawyerStatus, :michigan => MichiganLawyerStatus}

  def initialize(state = nil)
    super
    if state.nil? or !state.in?(URLS.keys)
      state=:georgia
    end

    run_id_class = RunId.new(state)
    @run_id = run_id_class.run_id
    @db_model = DB_MODELS[state]


    process_end = gathering(state)
    if process_end==1
      deleted_for_not_equal_run_id(@run_id, @db_model)
      run_id_class.finish
    end
  end

  URLS = {
    :georgia => "https://gabar.reliaguide.com/",
    :indiana => "https://inbar.reliaguide.com/",
    :michigan => "https://sbm.reliaguide.com/",
    :illinois2 => "https://isba.reliaguide.com/"
    }

  def gathering(state)
    limit = 20
    page = 0

    peon = Peon.new(storehouse)
    file = "last_page_#{state}"

    if "#{file}.gz".in? peon.give_list()
      page, = peon.give(file:file).split(':').map { |i| i.to_i }
    end
    cobble = Dasher.new(:using=>:hammer) #, ssl_verify:false

    count_waiter = 0
    loop do
        p page

        url_main = URLS[state] + "api/public/profiles?memberTypeId.equals=0&page=#{page}&size=20"

        trying = 0
        begin
          page_list_lawyers = cobble.get(url_main)
        #peon.put content:page_list_lawyers, file: letter, subfolder: state

          general_lawyers_array = parse_list_lawyers(page_list_lawyers, state)
        rescue => error
          if trying>2
            mess = "\nError: #{state}|#{error}"
            log mess, :red
            Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
            exit 0
          end

          trying+=1
          retry
        end

        bar_number_array = general_lawyers_array.map { |row| row[:bar_number] }

        existing_md5_hash = get_md5_hash(bar_number_array, @db_model)
        full_lawyer_array = []
        md5_hash_array = []

        general_lawyers_array.each do |lawyer|

          lawyer[:md5_hash] = make_md5(lawyer)
          if lawyer[:md5_hash].in? existing_md5_hash
            md5_hash_array.push(lawyer[:md5_hash])
            next
          end

          lawyer[:run_id] = @run_id
          lawyer[:touched_run_id] = @run_id

          full_lawyer_array.push(lawyer)

        end

        insert_all(full_lawyer_array, @db_model) unless full_lawyer_array.empty?
        put_new_touched_id(md5_hash_array, @run_id, @db_model)

        break if general_lawyers_array.length < limit
        page += 1
        peon.put(content: "#{page}:", file: file)
        count_waiter += 1
        if count_waiter == 20
          sleep 10
          count_waiter = 0
        end
    end
    peon.put(content: "0:", file: file)
    1
  end
end