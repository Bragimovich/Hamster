require_relative '../models/us_dept_conj'

class Parser < Hamster::Harvester

  def main()
    US_dc.connection
    count_rows_start = US_dc.count
    US_dc.clear_active_connections!
    run_id = run

    files = peon.give_list
    index = 1
    files_count = files.count
    files.each do |file|
      file = file.sub(/\.gz$/, '')
      link = "https://judiciary.house.gov/news/documentsingle.aspx?DocumentID=#{file.sub(/\.html$/, '')}"
      body = peon.give(file: file)
      page = Nokogiri::HTML.parse(body).css('.custom-mixed')

      title = title(page)
      date = date(page)
      article = article(page)
      teaser = teaser(article)

      with_table = table(article)
      article = article.to_s.squeeze(' ').strip
      dirty_news = title.empty? || article.empty? || teaser.empty? || teaser.length < 50

      h = {
        title: title,
        teaser: teaser,
        article: article,
        date: date,
        link: link,
        with_table: with_table,
        dirty_news: dirty_news
      }

      US_dc.connection
      US_dc.insert(h.merge({ run_id: run_id }))
      puts "[#{index}/#{files_count}] FILE ADD IN DATABASE! #{file}".green
      index += 1
      US_dc.clear_active_connections!


      #puts 'Run id:'.colorize(:red) + " #{run_id}"
      #puts 'Title:'.colorize(:red) + " #{title}"
      #puts 'Teaser:'.colorize(:red) + " #{teaser}"
      #puts 'Article:'.colorize(:red) + " #{article}"
      #puts 'Link:'.colorize(:red) + " #{link}"
      #puts 'Date:'.colorize(:red) + " #{date}"
      #puts 'With table:'.colorize(:red) + " #{with_table.to_s}"
      #puts 'Dirty news'.colorize(:red) + " #{dirty_news.to_s}"

    rescue StandardError => e
      message = "PAGE: #{link}\nError: #{e.message}\nBacktrace:#{e.backtrace}".red
      puts message
      message_send(message)
    end

    US_dc.connection
    count_rows_end = US_dc.count
    US_dc.clear_active_connections!
    count_rows_new = count_rows_end - count_rows_start
    if count_rows_new > 0
      message = "Add #{count_rows_new} new rows to table.".green
    else
      message = "No new rows to table.".green
    end
    puts message
    message_send(message)
  end

  # RUN ID

  def run
    US_dc.connection
    run_id = 1
    run = US_dc.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    US_dc.clear_active_connections!

    run_id
  end

  # RUN ID END

  # TITLE

  def title(page)
    title = page.css('.single-headline .newsie-titler').text.to_s.strip
    cut_title_length(title)
  end

  def cut_title_length(title)
    title = cut_title(title) if title.size > 200
    title&.sub(/:$/, '...')
  end

  def cut_title(title)
    title = title[0, 193].strip
    while title.scan(/\w{3,}$/)[0].nil?
      title = title[0, title.size - 1]
    end
    title
  end

  # TITLE END

  # TEASER

  def teaser(article)

    teasers = article.css('p', 'div')
    if teasers.empty?
      if article.to_s.index('<br>').nil?
        teaser = article.text.to_s.gsub(/\s/, ' ').gsub(' ', ' ').squeeze(' ').strip
      else
        teaser = article.to_s
        teaser = teaser[0, teaser.index('<br>')]
        teaser = Nokogiri::HTML.parse(teaser)
        teaser = teaser.text.to_s.gsub(/\s/, ' ').gsub(' ', ' ').squeeze(' ').strip
      end

    else
      teaser_count = teasers.count
      teaser = ''
      (0..teaser_count).each do |item|
        teaser = teasers[item].text.to_s.gsub(/\s/, ' ').gsub(' ', ' ').squeeze(' ').strip unless teasers[item].nil?
        break if teaser != '' && teaser.length > 50
      end
    end
    cut_teaser_length(teaser)
  end

  def cut_teaser_length(teaser)
    teaser = select_shortest_sentence(teaser)
    teaser = cut_sentence(teaser) if teaser.size > 600
    teaser&.sub(/:$/, '...')
  end

  def select_shortest_sentence(teaser)
    ids = []
    if teaser.size > 600
      sentence_ends = teaser.scan(/\w{3,}[.]|\w{3,}[?]|\w{3,}!/)
      sentence_ends.each do |sentence_end|
        ids << ((teaser.index sentence_end) + sentence_end.size)
      end
      teaser_new_length = ids.select{ |id| id <= 600 }.max
      teaser_new_length = 600 if !teaser_new_length.nil? && teaser_new_length < 60 #modify by igor sas
      teaser = teaser[0, teaser_new_length] unless teaser_new_length.nil?
    end
    teaser
  end

  def cut_sentence(teaser)
    teaser = teaser[0, 597].strip
    while teaser.scan(/\w{3,}$/)[0].nil?
      teaser = teaser[0, teaser.size - 1]
    end
    teaser
  end

  # TEASER END

  # ARTICLE

  def article(page)
    page.css('.main-newscopy .newsbody .bodycopy')
  end

  # ARTICLE END

  # DATE

  def date(page)
    date = page.css('.news-specs .topnewstext').text.strip
    date = date.gsub(/\s/, ' ')
    date = date[date.index(/,\s[a-zA-Z0-9 ]+,\s[a-zA-Z0-9 ]+$/), date.length]
    date = date.gsub(/^,/, ' ').strip
    Date.parse(date)
  end

  # DATE END

  # TABLE

  def table(page)
    page.to_s.include? '</table>'
  end

  # TABLE END

  def message_send(message)
    task_title = 'Scrape - #187'
    name_to = 'Igor Sas'
    Hamster.report(to: name_to, message: "#{task_title}\n#{message.uncolorize}")
  end

end
