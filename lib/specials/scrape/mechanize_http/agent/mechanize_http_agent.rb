class Mechanize::HTTP::Agent
  def set_proxy addr, port = nil, user = nil, pass = nil
    case addr
    when URI::HTTP
      proxy_uri = addr.dup
    when %r{\Asocks?://}i
      proxy_uri = URI addr
    when %r{\Ahttps?://}i
      proxy_uri = URI addr
    when String
      proxy_uri = URI "http://#{addr}"
    when nil
      @http.proxy = nil
      return
    end

    case port
    when Integer
      proxy_uri.port = port
    when nil
    else
      begin
        proxy_uri.port = Socket.getservbyname port
      rescue SocketError
        begin
          proxy_uri.port = Integer port
        rescue ArgumentError
          raise ArgumentError, "invalid value for port: #{port.inspect}"
        end
      end
    end

    proxy_uri.user = user if user
    proxy_uri.password = pass if pass

    @http.proxy = proxy_uri
  end

end
