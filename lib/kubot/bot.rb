module Kubot
  class Bot
    class << self
      def responders
        @responders ||= []
      end

      def respond(*conds, &block)
        responders << [conds, block]
        self
      end

      def reset
        @responders = []
        self
      end

      def inherited(klass)
        (@bots ||= []) << klass
      end

      def bots
        @bots ||= []
      end

      def bots_diff
        a = bots.dup
        yield
        bots-a
      end
    end

    def initialize(options={},config={})
      @options = options
      @config = config
    end

    attr_reader :config

    def db; @options[:db]; end

    def fire(message)
      self.class.responders.each do |responder|
        matchs = message.match(*responder[0])
        responder[1].yield self, message, matchs if matchs
      end
      self.respond_to?(method = :"on_#{message.type}") && self.__send__(method, message)
      self
    end

    def bot_name
      self.class.name \
          .gsub(/([A-Z]{2,}?)([a-z0-9])/){ $1.downcase + "_" + $2 } \
          .gsub(/([a-z0-9])([A-Z])/){ $1 + "_" + $2.downcase }.downcase
    end
  end
end
