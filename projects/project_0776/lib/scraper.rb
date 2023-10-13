require 'google_drive'

class Scraper < Hamster::Scraper

  def scrape
    credentials = Google::Auth::UserRefreshCredentials.new(Storage.new.auth_hamster)
    session     = GoogleDrive::Session.from_credentials(credentials)
    arg         = '1FvS4QeI2VD9DX59M7CeA_AmryDhl1U05eZDYNmMbPxE'
    spreadsheet = session.send(:file_by_id, arg)
  end
end





