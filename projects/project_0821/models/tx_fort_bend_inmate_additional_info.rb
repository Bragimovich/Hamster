# frozen_string_literal: true

require_relative 'tx_fort_bend_inmateable'
class TxFortBendInmateAdditionalInfo < ActiveRecord::Base
  include TxFortBendInmateable

  self.table_name = 'tx_fort_bend_inmate_additional_info'
end
