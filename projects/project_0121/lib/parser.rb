# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML(doc)
  end

  def check_next_page
    (@html.css('.pager__item--next').at("span:contains('Next page')")).nil?
  end

  def press_release_list
    @html.css("div.nir-widget--content div.nir-widget--list > article").map do |item|
      title = item.css("h3.article-headline").text.squish
      href = item.css("h3.article-headline a").attr("href").text
      teaser = item.css("div.nir-widget--news--teaser").text.squish
      date = DateTime.parse(item.css("div.article-date").text.squish).strftime("%Y-%m-%d")

      { 
        url: href,
        title: title, 
        teaser: teaser, 
        date: date
       }
    end
  end

  def release_data
    article = @html.css("div[class='node__content']")
    
    media_contact = article.at("strong:contains('MEDIA CONTACT: ')").parent.to_s rescue nil
    investor_contact = article.at("strong:contains('INVESTOR CONTACTS: ')").parent.to_s rescue nil
    !investor_contact.nil? ? contact_info =  (media_contact + investor_contact) : contact_info = media_contact

    {
      article: article.to_s,
      contact_info: contact_info
    }
  end
end
