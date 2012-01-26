module Kubot
  class Message
    def initialize(type, obj={})
      @type = type
      @obj = obj
    end
    attr_reader :type

    def method_missing(name, *args)
      @obj[name] || super
    end

    class InvalidMessage < StandardError; end
  end
end
