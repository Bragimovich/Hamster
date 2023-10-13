
class LoggerMsg < Hamster::Scraper

  def initialize
    super
  end

  def log(msg)
    msg = "#486 Crime Perp Scrape - Illinois Counties: " + msg
    Hamster::report(to: "Mikhail Golovanov", message: msg, use: :slack)
  end

  def log_begin
    log "Begin !"
  end

  def log_success
    log "Done !"
  end

  def log_error
    log "Error !"
  end

end
