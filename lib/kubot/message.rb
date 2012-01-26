module Kubot
  class Message
    @@validators = {}
    class << self
      def validator(type, &block)
        if block_given?
          @@validators[type] = block
        else
          @@validators[type]
        end
      end

      def validate(type, obj)
        return obj unless (v= self.validator(type))
        result = v[obj]
        if result.kind_of?(TrueClass)
          result = obj
        end
        result
      end
    end

    validator_help = ->(*keys) {
      ->(obj){ p keys; keys.all? {|key| obj.has_key?(key) } }
    }

    validator(:message, &validator_help[:message, :name, :room])
    validator(:enter, &validator_help[:name, :room])
    validator(:leave, &validator_help[:name, :room])
    validator(:kick, &validator_help[:name, :room, :target])
    validator(:name, &validator_help[:from, :to])


    def initialize(type, obj={})
      @type = type
      p obj
      unless @obj = self.class.validate(type, obj)
        raise InvalidMessage
      end
    end
    attr_reader :type

    def method_missing(name, *args)
      if /^(.+)\?$/ =~ name
        type == $1.to_sym
      else
        @obj[name]
      end
    end

    class InvalidMessage < StandardError; end
  end
end
