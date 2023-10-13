# frozen_string_literal: true

require_relative 'camouflage'

class ProxyFilter
  
  def initialize(duration: 600, touches: 100, &condition)
    @proxies     = {}
    @duration    = duration.is_a?(ActiveSupport::Duration) ? duration.to_i : duration
    @max_touches = touches
    @ban_reason  = condition
  end
  
  def ban(proxy)
    unless proxy.nil?
      if @proxies[proxy]
        @proxies[proxy][:touches] += 1
      else
        @proxies[proxy] = { start: Time.now, touches: 1 }
      end
    end
    nil
  end
  
  def ban_reason?(response)
    @ban_reason.nil? ? response.status != 200 : @ban_reason.call(response)
  end
  
  def ban_reason=(condition)
    @ban_reason = condition
  end
  
  def filter(proxy)
    result = nil
    unless proxy.nil?
      if @proxies.keys.include?(proxy)
        if @proxies[proxy][:touches] > @max_touches || (Time.now - @proxies[proxy][:start]) > @duration * 2 / 3 + rand(@duration / 3)
          @proxies.delete(proxy)
          result = proxy
        else
          @proxies[proxy][:touches] += 1
        end
      else
        result = proxy
      end
    end
    result
  end
  
  def count
    @proxies.count
  end
end

