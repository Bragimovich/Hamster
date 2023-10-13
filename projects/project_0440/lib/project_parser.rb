require_relative '../lib/parser'

class ProjectParser < Parser

  def initialize
    super
  end

  def years_paths
    elements_list(type: 'link', css: 'select#Year option', attribute: 'value')
  end

  def menu_links(url)
    css = 'a.ctl00_PlaceHolderMain_g_1b76115b_8ae5_45ab_be19_1321722f4c33_tvLeftNav_0'
    elements_list(type: 'link', css: css, url_prefix: url, range: 0..3)
  end

  def article_links
    elements_list(type: 'link', css: 'div.custom-contentTypeTitle a')
  end

  def parse_article
    title = elements_list(type: 'text', css: 'span.custom-snippetData', range: 0)
    article = elements_list(type: 'html', css: 'div.custom-contentTypeContent', range: 0)
    html = @html.css('div.custom-contentTypeBlock')[-1]
    contact_info = elements_list(type: 'html', css: 'span', html: html, range: -1)
    with_table = @html.css('div.custom-contentTypeContent').css("table").empty? ? 0 : 1
    {
      with_table: with_table,
      title: title,
      article: article,
      contact_info: contact_info
    }
  end

  def parse_titles
    data_first_part_arr = []
    types = elements_list(type: 'text', css: 'div.ms-srch-group-content div.custom-contentTypeCategory', downcase: true)
    dates = elements_list(type: 'date', css: 'div.ms-srch-group-content div.custom-contentTypeDate')
    links = article_links
    teasers = elements_list(type: 'teaser', css: 'div.ms-srch-group-content div.custom-contentTypeContent p')
    links_arr = []
    links_arr.append(*links)
    links_arr.each_with_index do |_, index|
      iter_data = {
        dirty_news: @dirty_news[index],
        link: links[index],
        type: types[index],
        date: dates[index],
        teaser: teasers[index]
      }
      data_first_part_arr << iter_data
    end
    data_first_part_arr
  end
end
