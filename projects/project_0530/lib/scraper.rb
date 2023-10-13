# frozen_string_literal: true

require 'socksify'

class Scraper < Hamster::Scraper

  def connect(**arguments, &block)
    begin
      @proxies = PaidProxy.where(is_socks5: 1).to_a
      @proxy = @proxies.sample
      proxy        = arguments[:proxy].dup || @proxy
      url          = arguments[:url].dup
      retries = 0
      proxy_addr = @proxy[:ip]
      proxy_port = @proxy[:port]
      proxy_user = @proxy[:login]
      proxy_passwd = @proxy[:pwd]
  
      TCPSocket.socks_username = proxy_user
      TCPSocket.socks_password = proxy_passwd
      uri = URI::parse(url)
      response = Net::HTTP.SOCKSProxy(proxy_addr, proxy_port).get(uri)

    rescue Exception => e
      retries += 1
      sleep(rand(15))
      
      if retries <= 15
        puts e.message
        puts e.full_message if @debug
        puts "Retry connection ##{retries}" if @debug
        retry
      else
        puts e.message
        Hamster.report(to: 'victor lynnyk', message: "530: def connect,message: #{e}")
        response = nil
      end
    else
      response 
    end
  end

  def link_by_forecast(loc)
    start_date = Time.now.strftime("%Y-%m-%d")
    date = Time.now + 432000
    end_date = date.strftime("%Y-%m-%d")
    response = connect(url: "https://api.open-meteo.com/v1/forecast?latitude=#{loc[0]}&longitude=#{loc[1]}&hourly=temperature_2m,relativehumidity_2m,apparent_temperature,precipitation,rain,showers,snowfall,snow_depth,freezinglevel_height,weathercode,windspeed_10m&daily=weathercode,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,precipitation_sum,rain_sum,showers_sum,snowfall_sum,windspeed_10m_max,windgusts_10m_max&temperature_unit=fahrenheit&timezone=#{loc[2]}&start_date=#{start_date}&end_date=#{end_date}")
    JSON.parse(response)
  end

  def link_by_historical(loc)
    start_date = "2021-01-01"
    end_date = Time.now.strftime("%Y-%m-%d")
    response = connect(url: "https://archive-api.open-meteo.com/v1/era5?latitude=#{loc[0]}&longitude=#{loc[1]}&start_date=#{start_date}&end_date=#{end_date}&hourly=temperature_2m,relativehumidity_2m,apparent_temperature,precipitation,rain,snowfall,cloudcover&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_sum,rain_sum,snowfall_sum,windspeed_10m_max,windgusts_10m_max&temperature_unit=fahrenheit&timezone=#{loc[2]}")
    JSON.parse(response)
  end

  def seach_zone(val)
    response = connect(url: "https://api.timezonedb.com/v2.1/get-time-zone?key=GER43OF116J2&format=json&by=position&lat=#{val[0]}&lng=#{val[1]}")
    JSON.parse(response)
  end
end
