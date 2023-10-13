class Parser < Hamster::Parser
  def parse(lawyers)
    data               = []
    def delete_spaces(text)
      text.gsub(/[[:space:]]/, ' ').squeeze(' ')
    end
    lawyers.each do |law_r|
      source  = "https://api-proxy.azbar.org/MemberSearch/Search?EntityNumber=#{law_r['EntityNumber']}&RequestorEntityNumber=undefined&{}"
      result                       = {}
      result[:bar_number]          = law_r['EntityNumber']
      result[:name]                = [law_r['NamePrefix'], law_r['FirstName'],
                                      law_r['MiddleName'], law_r['LastName'],
                                      law_r['NameSuffix']                                                      #clean_law_r[22]
                                     ].join(' ').gsub('   ', ' ').gsub('  ', ' ').strip
      result[:first_name]          = law_r['FirstName']
      result[:last_name]           = law_r['LastName']
      result[:middle_name]         = law_r['MiddleName']
      result[:name_prefix]         = law_r['NamePrefix']
      result[:date_admited]        = law_r['AzAdmitDate'].nil? ? nil : Date.parse(law_r['AzAdmitDate'])
      result[:registration_status] = law_r['MemberStatus']
      result[:sections]            = law_r['Sections'].join(', ')
      result[:phone]               = law_r['PhoneNumbers'][0].to_s.split(' ')[1]
      result[:email]               = law_r['Email']
      result[:law_firm_name]       = law_r['Company']
      result[:law_firm_address]    = [law_r['Address']['Address1'], law_r['Address']['Address2']].join(' ').strip
      result[:law_firm_zip]        = law_r['Address']['Zip']
      result[:law_firm_city]       = law_r['Address']['City']
      result[:law_firm_state]      = law_r['Address']['State']
      result[:law_firm_county]     = law_r['Address']['County']
      result[:law_firm_website]    = law_r['FirmURL']
      result[:university]          = law_r['LawSchool']
      result[:bio]                 = delete_spaces(Nokogiri::HTML(law_r['Bio']).text.strip)
      result[:other_jurisdictions] = law_r['Jurisdictions'].empty? ? nil : law_r['Jurisdictions'].join(', ')
      result[:data_source_url]     = source
      result.each {|key, val| result[key] = val.to_s.empty? ? nil : val}
      md5                          = MD5Hash.new(columns: [:bar_number, :first_name,
                                                           :last_name, :middle_name,
                                                           :name_prefix, :date_admited,
                                                           :registration_status, :sections,
                                                           :phone, :email,
                                                           :law_firm_name, :law_firm_address,
                                                           :law_firm_zip, :law_firm_city,
                                                           :law_firm_state, :law_firm_county,
                                                           :law_firm_website, :university,
                                                           :bio, :other_jurisdictions
                                                          ])
      result[:md5_hash]            = md5.generate(result)
      data << result
    end
    data
  end
end
