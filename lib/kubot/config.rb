require 'yaml'

module Kubot
  class Config
    def initialize(filename)
      @config = CustomHash[YAML.load_file(filename)]
    end

    def method_missing(name,*args)
      @config.__send__(name,*args)
    end

    # class CustomHash and CustomArray is public domain.
    # https://gist.github.com/1668637

    class CustomHash < Hash
      def self.new(a)
        self[a]
      end

      def self.[](a)
        h = super(a.to_a)
        h.keys.select{|key| key.kind_of?(String) }.each do |key|
          h[key.to_sym] = h.delete(key)
        end
        h.each do |key,value|
          case value
          when Array
            h[key] = CustomArray.new(value)
          when Hash
            h[key] = CustomHash[value]
          end
        end
        h
      end

      def method_missing(name,*args)
        self.has_key?(name) ? self[name] : nil
      end
    end

    class CustomArray < Array
      def initialize(*args)
        super *args
        self.map! do |x|
          if x.kind_of?(Hash) && x.class != CustomHash
            CustomHash.new(x)
          else; x; end
        end
      end
    end
  end
end
