module Kubot
  class Bot
    def bot_name
      self.class.name \
          .gsub(/([A-Z]{2,}?)([a-z0-9])/){ $1.downcase + "_" + $2 } \
          .gsub(/([a-z0-9])([A-Z])/){ $1 + "_" + $2.downcase }.downcase
    end


  end
end
