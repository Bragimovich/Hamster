# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse_key(source, key)
    begin
      res = JSON.parse(source.body)[key]
    rescue StandardError => e
      puts '*'*77, 'ERROR !!! Can`t parse this page', '*'*77
      return ERROR
    end
    return res unless res.instance_of?(Array)
    res.map { |record| record.merge(url: source.env.url.to_s) }
  end
end
