require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/message_send'

class Manager < Hamster::Scraper

  def download(options)
    scraper = Scraper.new
    date_today = Date.today
    dates = if options['date_start'].blank?
              ((date_today - 10)..date_today)
            else
              ((Date.parse(options['date_start']))..date_today)
            end
    dates.each do |date|
      cookie = scraper.cookie
      date_year = date.year.to_s
      date_month = format('%02d', date.month.to_s)
      date_day = format('%02d', date.day.to_s)
      req = "last=&first=&role=ALL&and%2For=and&last=&first=&role=ALL&issues1=ALL&issuesAndOr=AND&issues2=ALL&"
      req += "casetype=ALL&status=ALL&event=ALL&fromDate=#{date_month}%2F#{date_day}%2F#{date_year}&"
      req += "toDate=#{date_month}%2F#{date_day}%2F#{date_year}&searchtype=A&search=Search"
      items = scraper.items(req, cookie)
      next if items.blank?
      items.each do |item|
        case_id = item[:case_id]
        next if peon.give_list.include?("#{case_id}.html.gz")
        status = item[:case_status]
        summary = scraper.summary(case_id, cookie)
        long = scraper.long(case_id, cookie)
        docket = scraper.docket(case_id, cookie)
        parties = scraper.parties(case_id, cookie)
        parties_content = []
        parties.each do |party|
          party_name = party[:party_name]
          party_type = party[:party_type]
          party_link = party[:party_link]
          party = scraper.party(party_link, cookie)
          parties_content << { party_name: party_name, party_type: party_type, party_content: party.body}
        end
        page_save(case_id, status, summary, long, docket, parties_content)
      end
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
    message_send('Download finish!')
  end

  def page_save(case_id, status, summary, long, docket, parties_content)
    content = "<p><b>case_id: </b><span class='original_case_id'>#{case_id}</span></p>"
    content += "<p><b>status: </b><span class='original_case_status'>#{status}</span></p>"
    link_summary = "https://www.iowacourts.state.ia.us/ESAWebApp/AViewCase?caseid=#{case_id}&screen=null"
    link_long = "https://www.iowacourts.state.ia.us/ESAWebApp/AViewLongTitle?caseid=#{case_id}&screen=null"
    link_docket = "https://www.iowacourts.state.ia.us/ESAWebApp/AViewDocket?caseid=#{case_id}&screen=null"
    link_parties = "https://www.iowacourts.state.ia.us/ESAWebApp/AViewParties?caseid=#{case_id}&screen=null"
    content += "<p><b>link_summary: </b><a class='original_link_summary' href='#{link_summary}'>#{link_summary}</a></p>"
    content += "<p><b>link_long: </b><a class='original_link_long' href='#{link_long}'>#{link_long}</a></p>"
    content += "<p><b>link_docket: </b><a class='original_link_docket' href='#{link_docket}'>#{link_docket}</a></p>"
    content += "<p><b>link_parties: </b><a class='original_link_parties' href='#{link_parties}'>#{link_parties}</a></p>"
    content += "<h2><b>Summary</b></h2>"
    content += "<div class='original_summary'>#{summary.body}</div>"
    content += "<h2><b>Long</b></h2>"
    content += "<div class='original_long'>#{long.body}</div>"
    content += "<h2><b>Docket</b></h2>"
    content += "<div class='original_docket'>#{docket.body}</div>"
    parties_content.each do |item|
      content += "<h2><b>Party</b></h2>"
      content += "<div class='original_party'>"
      content += "<p><b>party_name: </b><span class='original_party_name'>#{item[:party_name]}</span></p>"
      content += "<p><b>party_type: </b><span class='original_party_type'>#{item[:party_type]}</span></p>"
      content += "<div class='original_party_content'>#{item[:party_content]}</div></div>"
    end
    name = "#{case_id}.html"
    peon.put(file: name, content: content)
    puts "PAGE SAVE! #{name}".blue
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    puts message
    message_send(message)
  end

  def store
    parser = Parser.new
    keeper = Keeper.new
    keeper.add_run('store start!')
    run_id = keeper.get_run
    index = 1
    files = peon.give_list
    files.each do |file|
      file = file.sub(/\.gz$/, '')
      page = peon.give(file: file)
      info = parser.info_parse(page)
      keeper.add_info(info, run_id, index) unless info.blank?
      add_info = parser.add_info_parse(page)
      keeper.add_add_info(add_info, run_id) unless add_info.blank?
      activities = parser.activities_parse(page)
      activities.each do |activity|
        keeper.add_activity(activity, run_id) unless activity.blank?
      end
      parties = parser.parties_parse(page)
      parties.each do |party|
        keeper.add_party(party, run_id) unless party.blank?
      end
      peon.move(file: file)
      index += 1
    rescue => e
      if e.message.include?('These is an issue connecting') || e.message.include?("Can't connect to MySQL")
        sleep(600)
        retry
      else
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        puts message
        message_send(message)
      end
    end
    peon.throw_trash
    keeper.update_run('store finish!')
    message_send('Store finish!')
  end
end
