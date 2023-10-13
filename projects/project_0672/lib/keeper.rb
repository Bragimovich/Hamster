# frozen_string_literal: true

require_relative '../models/raw_ky_jackson_county_inmates_arrests'

class Keeper

  def insert_data(data_array)
    data_array.each_slice(1000) {|e|
      puts "------------------- INSERTING DATA -------------------"
      safe_operation(RawKyJacksonCountyInmatesArrests) { |model| model.insert_all(e) } unless e.empty?
      puts "------------------- INSERTED DATA -------------------"
    }

  end
  
  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        puts "#{e.class}"
        puts "#{e.full_message}"
        puts '*'*77, "Reconnect!", '*'*77
        sleep 100
        model.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end
    retry
    end
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end
end
