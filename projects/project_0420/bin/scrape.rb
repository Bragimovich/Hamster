# frozen_string_literal: true
# require_relative '../lib/us_tax_exempt_organizations__american_express_foundation_parser'
# require_relative '../models/us_tax_exempt_organizations__american_express_foundation'
# require_relative '../models/us_tax_exempt_organizations_american_express_foundation_officers'
require_relative '../lib/american_express_founds_2019_parser'
require_relative '../models/american_express_founds_2019'

def scrape(options)
  # pr = UsTaxExemptOrganizationsAmericanExpressFoundationParser.new
  pr = AmericanExpressFounds2019Parser.new
  pr.parse
end

