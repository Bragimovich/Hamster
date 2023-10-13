# frozen_string_literal: true

def make_md5(news_hash)
  all_values_str = ''
  columns = %i[bar_number name link law_firm_name law_firm_county date_admitted registration_status eligibility law_school law_firm_website fax judicial_district]
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

  def initialize(update=0, continue=1)
    super
    run_id_class = RunId.new()
    @run_id = run_id_class.run_id
    @continue = continue
    answer = gathering(update)
    updating
    if answer==1
      #deleted_for_not_equal_run_id(@run_id) if update==1
      run_id_class.finish
    end
  end

  def gathering(update=0)
    limit = 50 # 10, 25 or 50
    page = 0
    peon = Peon.new(storehouse)
    file = 'last_page'
    states_array = USAStates.all().map { |row| row[:short_name] }
    first_state = states_array[0]
    if "#{file}.gz".in? peon.give_list() and @continue
      p 'hi'
      first_state, page, limit, first_law_school = peon.give(file:file).split(':').map { |q| q }
      page = page.to_i
      limit = limit.to_i
    end
    cobble = Dasher.new(:using=>:cobble, :redirect=>true)

    (first_state..states_array[-1]).each do |state|
      p state
      if state=='FL'
        law_schools_all = ["999", "1C", "5Y", "9S", "6T", "9J", "9C", "1F", "9W", "7Q", "1G", "1H", "6S", "1I", "1M", "2B", "7P", "2J", "6D", "1N", "9E", "9Q", "9Y", "1P", "8D", "1S", "1U", "1W", "1X", "2A", "2E", "1Y", "2F", "2G", "9Z1", "2H", "9P", "05", "9D", "10", "04", "2I", "7W", "2K", "2L", "8C", "2N", "2O", "7A", "2P", "6L", "2S", "2U", "2V", "7F", "2Y", "8G", "7B", "9O", "3I", "3H", "3G", "3F", "3E", "3J", "3M", "9V", "7X", "8M", "6P", "3W", "3X", "3Y", "4B", "7H", "7R", "4C", "4D", "06", "4E", "4F", "9R", "7M", "07", "2D", "6R", "8P", "6M", "7T", "8H", "8X", "4O", "3U", "4S", "4Q", "4W", "8V", "4X", "5E", "7J", "5F", "9Z3", "5B", "7C", "5G", "03", "4R", "4T", "8B", "5I", "5J", "5K", "8U", "5M", "7G", "8Y", "7K", "5P", "6W", "1A", "1B", "1D", "1E", "8L", "6K", "9Z2", "9X", "1L", "1K", "7Z", "2Q", "1Q", "1R", "1T", "1V", "7E", "1Z", "2C", "01", "2M", "7V", "2R", "2T", "2W", "2X", "3A", "3C", "9N", "6U", "3K", "9Z", "3L", "02", "3N", "3O", "3P", "3Q", "7S", "3R", "3T", "9I", "7L", "3V", "3Z", "4A", "4G", "4I", "4J", "4K", "4L", "4M", "4P", "4V", "4Z", "5A", "5C", "9L", "5L", "5N", "9A", "6X", "5O", "5Q", "5R", "5V", "6A", "6H", "6I", "5S", "5T", "6Y", "5U", "5W", "5X", "6B", "5Z", "6C", "6Q", "7D", "8I", "6E", "7I", "6O", "9U", "6F", "6G", "7U", "6J"]
        law_schools = []
        law_schools_all.each do |ls|
          next if !first_law_school.nil? and ls!=first_law_school
          law_schools.append('&lawSchool=' + ls.to_s)
        end
      else
        law_schools = ['']
      end

      first_law_school = nil

      law_schools.each do |ls_string|
        error = 0
        loop do
          p page

          url_main = "https://www.floridabar.org/directories/find-mbr/?locType=S&locValue=#{state}&sdx=Y&eligible=N&deceased=Y&pageNumber=#{page}&pageSize=#{limit}#{ls_string}"
          page_list_lawyers = cobble.get(url_main)

          general_lawyers_array = parse_list_lawyers(page_list_lawyers)

          #peon.put content:page_list_lawyers, file: "page#{page}"
          bar_numbers_array = general_lawyers_array.map { |row| row[:bar_number] }
          #existing_bar_numbers, existing_md5_hash = [], []
          existing_bar_numbers = existing_bar_number(bar_numbers_array) if update == 0
          existing_md5_hash = get_md5_hash(bar_numbers_array)

          full_lawyer_array = []
          md5_hash_array = []

          general_lawyers_array.each do |lawyer_general|
            next if update == 0 && existing_bar_numbers.include?(lawyer_general[:bar_number])

            retries = 0
            begin
              page_lawyer = cobble.get(lawyer_general[:link])
              #peon.put content:page_lawyer, file: lawyer_general[:bar_number].to_s
              other_lawyer = parse_lawyer(page_lawyer)
            rescue => error_message
              retries+=1
              sleep(60**retries)
              if retries>3
                mess = "\nError: #{lawyer_general[:link]}| #{error_message}"
                log mess, :red
                Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
                exit 0
              end
              retry
            end

            lawyer = lawyer_general.merge(other_lawyer)
            lawyer[:link] = lawyer_general[:link] if lawyer[:link].nil?
            lawyer[:md5_hash] = make_md5(lawyer)
            if existing_md5_hash.include?(lawyer[:md5_hash])  #and update == 1
              md5_hash_array.push(lawyer[:md5_hash])
              next
            end
            lawyer[:link] = lawyer[:link] if lawyer[:link].nil?
            lawyer[:run_id] = @run_id
            lawyer[:touched_run_id] = @run_id

            full_lawyer_array.push(lawyer)
          end
          begin
            insert_all full_lawyer_array unless full_lawyer_array.empty?
          rescue => e
            p e
            insert_all_each(full_lawyer_array)
          end

          deleted_md5=existing_md5_hash-md5_hash_array
          mark_deleted(deleted_md5)
          put_new_touched_id(md5_hash_array, @run_id)


          #exit 0 if general_lawyers_array.length==0
          if general_lawyers_array.length < limit
            if general_lawyers_array.length>0
              break
            else
              break if error>10
              error +=1
              redo
            end
          end
          #break if full_lawyer_array.length < limit && update==1
          peon.put(content: "#{state}:#{page}:#{limit}:#{ls_string}", file: file)
          puts '_______________'
          page+=1
        end
        page=0
        florida_db_reconnect
      end
    end
    peon.put(content: "#{states_array[0]}:0:50:", file: file)
    1
  end


  def updating
    limit = 100
    cobble = Dasher.new(:using=>:cobble, :redirect=>true)
    loop do
      lawyers = get_inupdated_lawyers(@run_id, limit:limit)

      full_lawyer_array = []
      md5_hash_array = []
      lawyers.each do |lawyer|
        page_lawyer = cobble.get(lawyer[:link])
        new_lawyer = parse_lawyer(page_lawyer)
        new_lawyer[:md5_hash] = make_md5(new_lawyer)
        if lawyer[:md5_hash] == new_lawyer[:md5_hash]
          lawyer.update(touched_run_id:@run_id)
          next
        else
          lawyer.update(deleted:1)
        end
        new_lawyer[:link] = lawyer[:link] if new_lawyer[:link].nil?
        new_lawyer[:run_id] = @run_id
        new_lawyer[:touched_run_id] = @run_id
        insert_all([new_lawyer])
        #full_lawyer_array.push(new_lawyer)
      end

      #insert_all full_lawyer_array unless full_lawyer_array.empty?
      p lawyers.length
      break
      break if lawyers.length<limit
    end

  end
end