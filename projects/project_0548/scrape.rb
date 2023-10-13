require_relative '../project_0548/lib/manager'
  def scrape(options)
    begin
      Hamster.report(to: 'Mashal Ahmad', message: "project_0548: scraping, parsing and storing Started!")
        manager = Manager.new  
        manager.download_store
      Hamster.report(to: 'Mashal Ahmad', message: "project_0548: Scraping, parsing and storing Finished!") 
      Hamster.report(to: 'Mashal Ahmad', message: "project_0548: Downloading parsing and storing Opinion files Started !") 
      manager.store_opinion
      Hamster.report(to: 'Mashal Ahmad', message: "project_0548: Downloading parsing and storing Opinion files Finished !")
      rescue Exception => e
        Hamster.report(to: 'Mashal Ahmad', message: "project_0548:\n#{e.full_message}")
    end
  end