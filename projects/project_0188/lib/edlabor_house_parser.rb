require_relative '../models/edlabor_house'

class EdlaborHouseParser < Hamster::Parser
  TASK_NAME = '#188 Federal Registry: Education & Labor Committee'.freeze
  SLACK_ID  = 'Eldar Eminov'.freeze

  def start
    files = peon.give_list
    count_parsing = 0
    unless files.empty?
      links_db = EdlaborHouse.all.select(:link).map(&:link)
      puts "We have #{files.size} files to parse".green
      files.each do |file|
        file_content  = peon.give(file: file)
        count_parsing = parsing_new_data(file_content, links_db, count_parsing)
      end
    end
    message = "#{TASK_NAME} --store:\nCompleted successfully parsing at #{Time.now}.\n"
    message += count_parsing.zero? ? 'We dont have new files or data.' : "Total parsed: #{count_parsing}"
    report_success(message)
  rescue StandardError => e
    p e
    Hamster.report(to: SLACK_ID, message: "#{TASK_NAME} --store: Error - \n#{e}", use: :both)
  end

  private

  def parsing_new_data(file_content, links_db, count_parsing)
    html         = Nokogiri::HTML(file_content)
    link         = html.css('head meta').find { |m| m['property'] == 'og:url' }['content']
    title        = html.at('#press h1.main_page_title').text.strip
    title        = "#{title[0, 202]}..." if title.size > 205
    date         = formalize_date(html.at('#press span.date strong')&.text)
    article_html = html.at('#press')
    article_html.children.each do |item|
      unnecessary_items = /#{['<div class="source"', '<span class="date', '<h1 class="main_page_title'].join('|')}/
      item.remove if item.to_html.match?(unnecessary_items)
    end

    article_html.at('table tr').remove if article_html.at('table tr')&.text&.include?('CONTACTS')
    article_html.search('img').each(&:remove)

    contacts = Nokogiri::HTML.fragment('')
    contact = false
    article_html.children.each do |item|
      contacts << item if contact
      contact = true if item.text.include?('Press Contact')
    end

    contact_info = contacts.text.empty? || contacts.to_html.size > 2200 ? nil : contacts.to_html
    article_html = remove_grates(article_html)
    article      = article_html.text.strip.empty? ? nil : article_html.to_html
    article_html.children.each { |item| item.remove if item.to_html.include?('<h2 class=') }
    teaser = article_html
    if teaser.text[0..350].include?('WASHINGTON') & !teaser.text[0..50].include?('WASHINGTON')
      teaser.children.each do |item|
        was_removed = true if item.text.include?('WASHINGTON')
        break if was_removed

        item.remove if !item.text.include?('WASHINGTON') && item.text.size < 200
      end
    end

    teaser     = cut_teaser_length(teaser.text.strip.gsub(' ', ' ')).strip
    with_table = article_html.include?('<table') && !article_html.at('table tr')&.text.include?(teaser)
    dirty      = article.nil?

    edlabor_house = EdlaborHouse.new
    edlabor_house.title        = title
    edlabor_house.date         = date
    edlabor_house.link         = link
    edlabor_house.article      = article
    edlabor_house.teaser       = teaser
    edlabor_house.contact_info = contact_info
    edlabor_house.dirty_news   = dirty
    edlabor_house.with_table   = with_table

    unless links_db.include?(link)
      edlabor_house.save
      count_parsing += 1
    end
    count_parsing
  end

  def remove_grates(block)
    all_remove = false
    block.children.each do |item|
      all_remove = true if !item.text.include?(block.text[100, 600]) && item.text.match?(/##|# #|Press Contact/)
      item.remove if all_remove
    end
    block.search('p').each   { |i| i.remove if i.text.size < 7 && i.text.match?(/##|# #/) }
    block.search('div').each { |i| i.remove if i.text.size < 7 && i.text.match?(/##|# #/) }
    block
  end

  def cut_teaser_length(teaser)
    return nil if teaser.nil?

    teaser = select_shortest_sentence(teaser)
    teaser = cut_sentence(teaser) if teaser.size > 600
    teaser&.sub(/:$/, '...')
  end

  def select_shortest_sentence(teaser)
    ids = []
    if teaser.size > 600
      sentence_ends = teaser[300..700].scan(/\w{3,}[.]|\w{3,}[?]|\w{3,}!/)
      sentence_ends.each do |sentence_end|
        ids << ((teaser.index sentence_end) + sentence_end.size)
      end
      teaser_new_length = ids.select { |id| id <= 600 }.max
      teaser = teaser[0, teaser_new_length] if teaser_new_length
    end
    teaser
  end

  def cut_sentence(teaser)
    teaser = teaser[0, 600].strip
    teaser = teaser[0, teaser.size - 1] while teaser.scan(/\w{3,}$/)[0].nil?
    teaser
  end

  def formalize_date(date)
    return nil if date.nil?

    date_array = date.split('.')
    year = "20#{date_array.pop}"
    date_array.unshift(year).join('-')
  end

  def report_success(message)
    puts message.green
    time = Time.now
    if time.wday >= 1 && time.wday <= 5 && time.hour > 1 && time.hour < 10
      Hamster.report(to: SLACK_ID, message: message, use: :both)
    end
  end
end
