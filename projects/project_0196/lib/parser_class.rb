require 'scylla'
class ParserClass
  
  BASE_URL2 = "https://www.ams.usda.gov"
  
  def data_from_div(article_div)
    temp = article_div.xpath('span')
    
    if temp.count == 2
      date,article = temp
      parsed_date = date.xpath('span').text
      link = article.xpath('span/a/@href').text
      title = article.xpath('span/a').text
    end
    
    if parsed_date.present?
      month , day, year = parsed_date.split('-')
      required_date = year + '-' + month + '-' + day
    end    
    
    partial_hash = {
      date: required_date,
      link: BASE_URL2 + link,
      title: title
    }
    partial_hash
  end

  def parse_each_article(file_content)
    dirty_news = false
    article_not_in_english = true
    parsed_article = Nokogiri::HTML(file_content)
    release_no_xpath = "/html/body/div/main/div/div/div/div/article/div/div[3]/div[2]"
    contact_info_div_path = "//*[@id='block-mainpagecontent']/article/div/div[2]/div[1]"
    contact_info_path = "//*[@id='block-mainpagecontent']/article/div/div[2]/div[2]"
    article_path = "//*[@id='block-mainpagecontent']/article/div/div[last()]"
    release_no = parsed_article.xpath(release_no_xpath).text
    contact_info1 = parsed_article.xpath(contact_info_div_path).to_html
    contact_info2 = parsed_article.xpath(contact_info_path).to_html
    article_div = parsed_article.xpath(article_path)

    if parsed_article.xpath(article_path).text.language == "english"
      article_not_in_english = false
    end

    teaser = ""

    if article_div&.children&.first&.text.include?("Release No")
      teaser = parse_teaser(article_div&.children[1]&.text)
      if release_no.nil? or release_no == ""
        release_no = article_div&.children&.first&.text&.split(".:")&.last&.strip
      end
      article_text_in_html = article_div&.children[1..-1]&.to_html
    else
      teaser = parse_teaser(article_div&.children[0]&.text)
      article_text_in_html = article_div&.to_html
    end

    # if release_no is still None or ""
    if release_no.nil? or release_no == ""
      article_div&.children.each do |child|
        if child&.text&.include?("AMS No.")
          release_no = child&.text.split("No.")&.first(2).last.strip
        end
      end
    end

    contact_info_combined = contact_info1 + contact_info2

    if contact_info_combined.class.to_s  == 'Nokogiri::XML::NodeSet'
      contact_info_combined = "N/A"
    end
  
    if article_text_in_html == "" or article_not_in_english
      dirty_news = true
    end

    created_hash = {
      article: article_text_in_html,
      contact_info: contact_info_combined, 
      teaser: teaser,
      dirty_news: dirty_news,
      release_no: release_no,
    }
    created_hash
  end

  def parse_teaser(first_paragraph)
    teaser = ""
    if first_paragraph.present?
      if first_paragraph.length > 600
        teaser = first_paragraph
        while true
          teaser = teaser.split('.')[1..-2].join(".")
          if teaser.length <= 600
            break
          end
        end
      else
        teaser = first_paragraph
      end
    end
    teaser
  end

  def get_inner_divs(file_content)
    parse_page = Nokogiri::HTML(file_content)
    all_divs_xpath = '/html/body/div/main/div/div/div/div/div/div/div[2]/div'
    parse_page.xpath(all_divs_xpath)
  end

  def get_article_link_from_inner_div(inner_div)
    inner_div.xpath('span/span/a/@href').text
  end
end