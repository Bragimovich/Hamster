# frozen_string_literal: true
class ParserClass

  def get_inner_divs(file_content)
    parse_page = Nokogiri::HTML(file_content)
    parse_page.xpath('//div[@class="a-grantsDatabase"]')
  end

  def parse_head_line(head_line)
    name , year, price =  head_line.xpath('div/div')
    
    name = name.xpath('h2').text.strip
    year = year.xpath('span').text.strip
    price = price.xpath('span').text.strip
    
    # converting price in to int
    price_in_int = price.sub("$" ,"").gsub(",","").to_i
    [name, year ,price_in_int]
  end

  def parse_details(details)
    theme = ""
    referring_program = ""
    term = ""
    region = ""
    funder = ""

    description = details.xpath("div/div/div/div")[0].xpath('p').text.strip # description

    count_of_headers = details.xpath("div/div/div")[1].xpath("div").count 

    (0...count_of_headers).each do |i|
      header = details.xpath("div/div/div")[1].xpath("div")[i].xpath('span').text.strip
      cols = details.xpath("div/div/div")[1].xpath("div")[i].xpath('p').text.strip

      if header == "Theme"
        theme = cols.squeeze.gsub("\n","|")

      elsif header == "Referring Program"
        referring_program = cols.squeeze(" ").gsub("\n","|")
      
      elsif header == "Term"
        term = cols.squeeze(" ").gsub("\n","|")

      elsif header == "Region"
        region = cols.squeeze(" ").gsub("\n","|")
      
      elsif header == "Funder"
        funder = cols
      end
    end
    [description ,theme , term , region , funder , referring_program]
  end

  def parse_each_div(article_div)
    grant_id = article_div["id"]
    temp = article_div.xpath('div')
    name , year, price =  parse_head_line(temp[0])

    description ,theme , term , region , funder , referring_program =  parse_details(temp[1])

    {
      grant_id: grant_id,
      name: name,
      year: year ,
      amount: price,
      description: description,
      theme: theme,
      term: term,
      funder: funder,
      referring_program: referring_program,
      region: region
    }
  end
end
 