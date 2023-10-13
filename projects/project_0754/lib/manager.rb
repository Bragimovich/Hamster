require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize(**options)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @slack_msg = Slack::Web::Client.new(token: Storage.new.slack)

    @md5_cash_maker = {
      :cei_data => MD5Hash.new(columns:%i[employer headquarters_location state year data_source_url]),
      :cei_data_rating => MD5Hash.new(columns:%i[cei_data_id name rating data_source_url])
    }

    @url = "https://hrc-prod-requests.s3-us-west-2.amazonaws.com/CEI-#{DateTime.now.year}-Appendices-G.pdf"

    download if options[:download]
    store if options[:store]
    send_slack_message if options[:send]
  end

  def download
    @scraper.download_pdf_file(@url)
  end

  def store

    hash_cei_data = {}
    hash_cei_data_rating = {}

    pdf_file = File.open("#{storehouse}/store/CEI-#{DateTime.now.year}-Appendices-G.pdf", 'rb')

    reader = PDF::Reader.new(pdf_file)

    reader.pages.each do |page|
      data = @parser.parse_pdf_page(page)

      data.each do |line|

        if line[0] != "Employer"
          hash_cei_data = {
            employer: line[0].strip,
            headquarters_location: line[1].strip,
            state: line[2].strip,
            year: DateTime.now.year,
            data_source_url: @url
          }
          hash_cei_data[:md5_hash] = @md5_cash_maker[:cei_data].generate(hash_cei_data)
          @keeper.save_data_to_cei_data(hash_cei_data)

          rating = @parser.parse_rating_data(line[-1])
          rating_name = ["#{DateTime.now.year} CEI Rating", "#{DateTime.now.year - 1} CEI Rating", 'Fortune 1000']

          (0..2).each do |index|
            hash_cei_data_rating = {
              cei_data_id: @keeper.get_cei_id(hash_cei_data[:md5_hash]),
              name: rating_name[index],
              rating: rating[index],
              data_source_url: @url
            }
            hash_cei_data_rating[:md5_hash] = @md5_cash_maker[:cei_data_rating].generate(hash_cei_data_rating)
            @keeper.save_data_to_cei_data_rating(hash_cei_data_rating)
          end
        end
      end
    end

    pdf_file.close
    @keeper.finish
  end

  def send_slack_message
    status = @scraper.check_status_of_url(@url)
    if status != 200
      retry_time = Time.now + 1.day # add 24 hours
      end_time = Time.now + 7.days # add 1 week
      while Time.now < end_time do
        # logger
        sleep(retry_time - Time.now)
        status = @scraper.check_status_of_url(@url)
        if status == 200
          text = "@channel #754 US Raw: Corporate Equality Index (CEI) dataset - The new data required for parsing"
          @slack_msg.chat_postMessage(channel: '0754_usa_raw_cei',
                                      text: text,
                                      link_names: true,
                                      as_user: true)
          break
        end
        retry_time += 1.day
      end
      if Time.now >= end_time and status != 200
        text = "@channel #754 US Raw: Corporate Equality Index (CEI) dataset - Starting from November 10, the link #{@url} was checked " /
          "for a week, but its status did not change (#{status}). It is required to check the data and provide it for parsing."
        @slack_msg.chat_postMessage(channel: '0754_usa_raw_cei',
                                    text: text,
                                    link_names: true,
                                    as_user: true)
      end
    else
      text = "@channel #754 US Raw: Corporate Equality Index (CEI) dataset - The new data required for parsing"
      @slack_msg.chat_postMessage(channel: '0754_usa_raw_cei',
                                  text: text,
                                  link_names: true,
                                  as_user: true)
    end
  @keeper.finish
  end


end
