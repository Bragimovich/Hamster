class Scraper < Hamster::Scraper

  def initialize
    super
    @cobble = Dasher.new(using: :cobble, redirect: true)
  end

  def download_pdf_file(url)
    5.times do
      response = Hamster.connect_to(url)
      file_name = "CEI-#{DateTime.now.year}-Appendices-G"
      # p response&.status
      if [200,301,304,308,307].include?(response&.status)
       @cobble.get_file(url, filename: file_name)
      end
      # return response.body if [200,301,304,308,307].include?(response&.status) end
    end
  end

  def check_status_of_url(url)
    5.times do
      response = Hamster.connect_to(url)
      return response&.status
    end
  end


end
