# frozen_string_literal: true

module Hamster
  module HamsterTools
    def countdown(period, header: '', label: '', store: nil)
      puts header unless header.empty?
      
      if period >= 1
        period.round.downto(0) do |i|
          stop_signal = "#{store}/timer_stop"
          stop        = File.exist?(stop_signal)
          
          if store && stop
            FileUtils.rm_rf(stop_signal)
            break
          end
          
          hours   = i / 3600
          minutes = (i - hours * 3600) / 60
          seconds = i - hours * 3600 - minutes * 60
          time    = "%02d:%02d:%02d" % [hours, minutes, seconds]
          print "\r#{label} #{time}".squeeze(' ') if Hamster.commands[:debug]
          sleep 1
        end
      else
        print label
        sleep period.abs
      end
      
      puts
    end
  end
end
