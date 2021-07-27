# does a DNS lookup and returns an array of strings of the results

require 'resolv'

Puppet::Functions.create_function(:'resolv') do
    dispatch :resolv do
      param 'String', :ip
      return_type 'String'
    end

    def resolv(ip)
      tuple = Resolv.new.getaddresses(ip)
      return tuple[0]
    end
end