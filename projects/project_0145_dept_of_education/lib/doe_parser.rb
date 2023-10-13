# frozen_string_literal: true

def parse_list_releases(html)
  doc = Nokogiri::HTML(html)
  press_releases = []
  #date_news = Date.new()
  html_list_releases = doc.css('.views-row')
  html_list_releases.each do |release|
    press_releases.push({})


    link = release.css('.views-field-field-custom-title a')[0]
    press_releases[-1][:link]   = link['href']
    press_releases[-1][:title]  = link.content
    press_releases[-1][:date]   = release.css('.date-display-single')[0].content
    press_releases[-1][:teaser] = release.css('.views-field-body')[0].content.strip
    press_releases[-1][:tags] = []
    release.css('.views-field-nothing').css('a').each do |tag|
      press_releases[-1][:tags].push(tag.content)
    end
  end
  press_releases
end


def parse_release(html)
  doc = Nokogiri::HTML(html)

  press_release = {}

  press_release[:title] = doc.css('.pane-page-title h1')[0].content
  press_release[:date] = doc.css('.pr-date')[0].content #todo: parse date
  press_release[:contact_info] = doc.css('.page-press-room-post-date')[0].to_s
  press_release[:article] = doc.css('.field-type-text-with-summary')[0].to_s

  press_release[:tags] = []
  doc.css('.view-id-tags').css('a').each do |tag|
    next if tag.content=='Press Releases"'
    press_release[:tags].push(tag.content)
  end
  press_release

end