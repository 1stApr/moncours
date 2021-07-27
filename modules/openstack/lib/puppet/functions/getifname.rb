# lookup and return interface name assosiated with given ip address

require 'socket'

Puppet::Functions.create_function(:'getifname') do
    dispatch :getifname do
      param 'String', :ip
      return_type 'String'
    end

    def getifname(ip)

      Socket.getifaddrs.each do |ifaddr|
        next unless ifaddr.addr.ipv4? && ifaddr.addr.ip_address.to_s == ip
        return ifaddr.name
      end 

      return "getifname(ip): Could not find interface name by ip: #{ip}"
    end
end

