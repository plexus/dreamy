module Dreamy
  class Control

    @@host = "api.dreamhost.com"

    def initialize(username, key)
      @username = username
      @key      = key
    end
    
    # returns an array of domain objects
    def domains
      doc = request("domain-list_domains")
      (doc/:data).inject([]) { |domains, domain| domains << Domain.new_from_xml(domain); domains }
    end
    
    # returns an array of user objects
    def users(passwords=false)
      if passwords
        doc = request("user-list_users")
      else
        doc = request("user-list_users_no_pw")
      end
      
      (doc/:data).inject([]) { |users, user| users << User.new_from_xml(user); users }
    end
    
    # returns an array of dns objects
    def dns
      doc = request("dns-list_records")
      (doc/:data).inject([]) { |records, dns| records << Dns.new_from_xml(dns); records }
    end
    
    def request(cmd,values={})
      handle_response!(response(cmd,values))
    end
    
     private

    def response(cmd,values={})
      params = [
        "username=#{@username}",
        "key=#{@key}",
        "cmd=#{cmd}",
        "format=xml",
        "unique_id=#{UUID.new.generate}",
      ]
      
      path = "/?#{params.join("&")}"
      http = Net::HTTP.new(@@host, 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      begin
        response = http.get(path)
      rescue => error
        raise CantConnect, error.message
      end
    end
    
    def handle_response!(response)
      if %w[200 304].include?(response.code)
        response = parse(response.body)
      elsif response.code == '503'
        raise Unavailable, response.message
      elsif response.code == '401'
        raise CantConnect, 'Authentication failed. Check your username and password'
      else
        raise CantConnect, "Dreamy is returning a #{response.code}: #{response.message}"
      end
    end
    
    # Converts a string response into an Hpricot xml element.
    def parse(response)
      Hpricot.XML(response || '')
    end

  end
end