require_relative '../models/us_tax_exempt_organizations__american_express_foundation'

class  UsTaxExemptOrganizationsAmericanExpressFoundationParser < Hamster::Harvester
  NODE_NAMES_ORG = %w[AddressLine1Txt
                      AddressLine2Txt
                      Amt
                      BusinessNameLine1Txt
                      CityNm
                      CountryCd
                      ForeignPostalCd
                      GrantOrContributionPurposeTxt
                      ProvinceOrStateNm
                      RecipientBusinessName
                      RecipientForeignAddress
                      RecipientFoundationStatusTxt
                      RecipientRelationshipTxt
                      RecipientUSAddress
                      StateAbbreviationCd
                      ZIPCd
                      GrantOrContributionPdDurYrGrp
                      GrantOrContriApprvForFutGrp
  ].freeze

  NODE_NAMES_OFFICER = %w[AddressLine1Txt
                          AddressLine2Txt
                          AverageHrsPerWkDevotedToPosRt
                          CityNm
                          CompensationAmt
                          EmployeeBenefitProgramAmt
                          ExpenseAccountOtherAllwncAmt
                          OfficerDirTrstKeyEmplGrp
                          PersonNm
                          StateAbbreviationCd
                          TitleTxt
                          USAddress
                          ZIPCd
  ].freeze
                          # OfficerDirTrstKeyEmplInfoGrp

  def initialize
    super
    @peon = Peon.new(storehouse)
    @file_path = "#{storehouse}store/202112259349100316_public.xml"
  end

  def parse
    xml = Nokogiri::XML(File.open(@file_path))
    # pars_orgs(xml)
    pars_officers(xml)
  end

  private

  def pars_orgs(xml)
    grants = xml.css("GrantOrContributionPdDurYrGrp") + xml.css("GrantOrContriApprvForFutGrp")

    grants.each do |rec|
      h = {}
      rec.traverse do |node|
        next unless node.instance_of?(Nokogiri::XML::Element)

        raise "Unknown node name #{node.name}" unless NODE_NAMES_ORG.include?(node.name)

        h[node.name.to_sym] = node.text
      end
      raise "#{h[:BusinessNameLine1Txt]} has both US and foreign address." if h.has_key?(:RecipientUSAddress) && h.has_key?(:RecipientForeignAddress)

      raise "#{h[:BusinessNameLine1Txt]} has non-digital amount." if h[:Amt].match?(/\D/)

      UsTaxExemptOrganizationsAmericanExpressFoundation.find_or_create_by(
        organization: h[:BusinessNameLine1Txt],
        address_ln1: h[:AddressLine1Txt],
        address_ln2: h[:AddressLine2Txt],
        city: h[:CityNm],
        # state: h[:StateAbbreviationCd],
        # province_or_state: h[:ProvinceOrStateNm],
        province_or_state: h.key?(:StateAbbreviationCd) ? h[:StateAbbreviationCd] : h[:ProvinceOrStateNm],
        zip: h.key?(:ZIPCd) ? format_zip(h[:ZIPCd]) : h[:ForeignPostalCd],
        country: h.key?(:RecipientUSAddress) ? 'US' : h[:CountryCd],
        relationship: h[:RecipientRelationshipTxt],
        status: h[:RecipientFoundationStatusTxt],
        purpose: h[:GrantOrContributionPurposeTxt],
        amount: h[:Amt],
        payed_or_approved: h.key?(:GrantOrContributionPdDurYrGrp) ? 'payed' : 'approved'
      )
    end

  rescue ActiveRecord::ActiveRecordError => e
    @logger.error(e)
    raise
  end

  def pars_officers(xml)
    officers = xml.css("OfficerDirTrstKeyEmplGrp")

    officers.each do |rec|
      h = {}
      rec.traverse do |node|
        next unless node.instance_of?(Nokogiri::XML::Element)

        raise "Unknown node name #{node.name}" unless NODE_NAMES_OFFICER.include?(node.name)

        h[node.name.to_sym] = node.text
      end
      raise "#{h[:PersonNm]} has non-digital hours." if h[:AverageHrsPerWkDevotedToPosRt].match?(/[^.\d]/)
      raise "#{h[:PersonNm]} has non-digital compensation." if h[:CompensationAmt].match?(/[^.\d]/)
      raise "#{h[:PersonNm]} has non-digital benefit." if h[:EmployeeBenefitProgramAmt].match?(/[^.\d]/)
      raise "#{h[:PersonNm]} has non-digital expense." if h[:ExpenseAccountOtherAllwncAmt].match?(/[^.\d]/)

      UsTaxExemptOrganizationsAmericanExpressFoundationOfficers.find_or_create_by(
        name: h[:PersonNm],
        address_ln1: h[:AddressLine1Txt],
        address_ln2: h[:AddressLine2Txt],
        city: h[:CityNm],
        state: h[:StateAbbreviationCd],
        # province_or_state: h[:ProvinceOrStateNm],
        # province_or_state: h.key?(:StateAbbreviationCd) ? h[:StateAbbreviationCd] : h[:ProvinceOrStateNm],
        zip: format_zip(h[:ZIPCd]),
        country: 'US',
        title: h[:TitleTxt],
        avg_hours: h[:AverageHrsPerWkDevotedToPosRt],
        compensation_amount: h[:CompensationAmt],
        benefit_amount: h[:EmployeeBenefitProgramAmt],
        expense_amount: h[:ExpenseAccountOtherAllwncAmt],
      )
    end

  rescue ActiveRecord::ActiveRecordError => e
    @logger.error(e)
    raise
  end

  def format_zip(zip)
    # puts cell.inspect
    if zip.size == 9
      "#{zip[0..4]}-#{zip[-4..-1]}"
    else
      zip
    end
  end
end


