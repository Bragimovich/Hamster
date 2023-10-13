# frozen_string_literal: true

class ScraperFLSAAC < Hamster::Scraper

  def initialize(**options)
    super
    @cobble = Dasher.new(:using=>:cobble, :pc=>1)
  end

  def parties(court:'1',letter:'A', type:'Party')
    url =
      if court=='sa'
        "http://onlinedocketssc.flcourts.org/DocketResults/Person?Searchtype=Party+or+Attorney&CaseTypeSelected=All&SearchEntity=#{type}&SelectedMatch=Starts+With&LastName=#{letter}&FirstName=&MiddleName=&BarPrisonerNo="
      else
        "http://onlinedocketsdca.flcourts.org/DCAResults/Person?Searchtype=Party+or+Attorney&Court=#{court}&SearchEntity=#{type}&SelectedMatch=Starts+With&LastName=#{letter}&FirstName=&BarPrisonerNo="
      end
    @cobble.get(url)
  end

  def cases_date_filed(court_id:320, date:Date.today-1)
    date_string = date.strftime('%m/%d/%Y')
    url =
      if court_id<400
        "http://onlinedocketssc.flcourts.org/DocketResults/CaseDate?Searchtype=Date+Filed&Status=All+Cases&DocketType=All&FromDate=#{date_string}&ToDate=#{date_string}"
      else
        court = court_id-414
        "http://onlinedocketsdca.flcourts.org/DCAResults/CaseDate?Searchtype=Date+Filed&court=#{court}&Status=All+Cases&DocketType=All&FromDate=#{date_string}&ToDate=#{date_string}"
      end
    @cobble.get(url)
  end

  def get_page(url)
    @cobble.get(url)
  end


end
