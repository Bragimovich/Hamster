require 'scylla'

class Parser

  def extract_links(outer_page)
    body = Nokogiri::HTML(outer_page)
    links = body.css("div.fig-graphic")
    result = links.map{|item| item.css("a")}
    final = result.flatten().map {|item|  item.attr('href') }
    final
  end

  def parse_inner_page(inner_page, link)
    data = Nokogiri::HTML(inner_page)
    article_data = data.xpath("//div[@class='container__column container__column--story center-horizontally']")

    empty_article = article_data.text.delete("\n") == ""
    if empty_article
      title = data.xpath("//div[@class='media-intro color-inverted']/div/header").text.delete("\n")
      teaser = nil
      article = nil
      date = data.xpath("//div[@class='media-intro color-inverted']/div/footer/p[@class='timestamp']/time").attr('datetime').value
      with_table = 0
      dirty_news = 1
      tags = []
      authors = get_authors(data.xpath("//div[@class='media-intro color-inverted']/div/footer/p[@class='byline']").text.delete("\n"))
    else
      title = data.xpath("//h2[@class='headline']").text.delete("\n")
      teaser = get_teaser(article_data.xpath("//p[@class='story-text__paragraph  ']")[0]&.text)
      article = article_data.to_html
      date = article_data.xpath("//time").attr('datetime').value
      with_table = article_data.xpath("//table").length != 0 ? 1 : 0
      dirty_news = (article_data.text.language != "english") ? 1 : 0
      tags = article_data.xpath("//div[@class='story-tags']").text.delete("\n").split(": ")[1].split(", ").map{ |item| item.strip }
      authors = get_authors(article_data.xpath("//p[@class='story-meta__authors']").text)
    end

    {
      title: title,
      teaser: teaser,
      article: article,
      date: date,
      link: link,
      with_table: with_table,
      dirty_news: dirty_news,
      tags: tags,
      authors: authors
    }
  end

  private 

  def get_authors(text)
    authors = text.split("By ")[1]
    authors = authors==nil ? [] : authors.strip.gsub(" and ",", ").split(", ")
  end

  def get_teaser(text)
    if (text.length <= 600)
      teaser = text
    else
      teaser = text[..599].split()
      if text[600]== "."
        teaser.join(" ")
      else
        index= -1 
        while true
          if teaser[index].length >3
            teaser[index] = teaser[index]+"..."
            break
          end
          break if teaser[index] == nil
          index-=1
          teaser.pop()
        end
        teaser.join(" ")
      end
    end
  end

end