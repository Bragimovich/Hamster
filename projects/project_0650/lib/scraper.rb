# frozen_string_literal: true

class Scraper <  Hamster::Scraper
  MAIN_URL = 'https://ujsportal.pacourts.us/CaseSearch'

  def main_page(url = '')
    url.empty? ? connect_to(MAIN_URL) : connect_to(url)
  end

  def get_page_request(headers, startDate, endDate, requestVerificationToken)
    body = prepare_body(startDate, endDate, requestVerificationToken)
    connect_to(url: MAIN_URL, headers: headers, method: :post, req_body: body)
  end

  private

  def prepare_body(filedStartDate, filedEndDate, requestVerificationToken)
    "SearchBy=DateFiled&AdvanceSearch=true&ParticipantSID=&ParticipantSSN=&FiledStartDate=#{filedStartDate}&FiledEndDate=#{filedEndDate}&County=Bucks&JudicialDistrict=&MDJSCourtOffice=&DocketType=&CaseCategory=&CaseStatus=&DriversLicenseState=&PADriversLicenseNumber=&ArrestingAgency=&ORI=&JudgeNameID=&AppellateCourtName=&AppellateDistrict=&AppellateDocketType=&AppellateCaseCategory=&AppellateCaseType=&AppellateAgency=&AppellateTrialCourt=&AppellateTrialCourtJudge=&AppellateCaseStatus=&ParticipantRole=&ParcelState=&ParcelCounty=&ParcelMunicipality=&CourtOffice=&CourtRoomID=&CalendarEventStartDate=&CalendarEventEndDate=&CalendarEventType=&__RequestVerificationToken=#{requestVerificationToken}"
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 503, 304 ,302].include?(response.status)
    end
    response
  end
end
