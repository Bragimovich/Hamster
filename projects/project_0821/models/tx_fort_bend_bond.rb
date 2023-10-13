# frozen_string_literal: true

require_relative 'tx_fort_bend_inmateable'
class TxFortBendBond < ActiveRecord::Base
  include TxFortBendInmateable
end
