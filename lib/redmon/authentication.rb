module Redmon
  module Authentication
    
    def self.extended(base)
      base.send(:authenticate) if Redmon.config.authentication
    end
    
    def authenticate
      use Rack::Auth::Basic, "Restricted Access" do |username, password|
        [username, password] == [Redmon.config.username, Redmon.config.password]
      end
    end
    
  end
end