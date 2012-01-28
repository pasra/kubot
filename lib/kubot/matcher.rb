# matcher.rb - simple flexible matcher

# Original: https://github.com/sorah/sandbox/blob/master/ruby/matcher/matcher.rb
# Original Author: Shota Fukumori (sora_h)
# License: Public domain

module Kubot
  class Matcher
    DEFAULT_KEY = :foo

    def initialize(obj, default = DEFAULT_KEY)
      @default = default
      @obj = obj
    end

    def match(*args)
      matchs = []
      mash = {}
      la, lb = ->(conds, method = :any?) do
        conds.__send__(method) do |cond|
          case cond
          when Array
            la[cond]
          when Hash
            lb[cond]
          when Regexp
            @obj[@default].kind_of?(String) && (matchs << @obj[@default].match(cond))[-1]
          else
            @obj[@default] == cond && (matchs << cond)[-1]
          end
        end
      end, ->(hash, method = :any?) do
        hash.__send__(method) do |key,value|
          case key
          when :any
            case value
            when Array
              return la[value]
            when Hash
              return lb[value]
            else
              raise TypeError
            end
          when :all
            case value
            when Array
              return la[value, :all?]
            when Hash
              return lb[value, :all?]
            else
              raise TypeError
            end
          else
            case value
            when Hash
              if value.has_key?(:raw) && value.size == 1
                value = [value[:raw]]
              else
                value = [value]
              end
            when Array
            else
              value = [value]
            end

            # TODO: hierarchical hash
            return value.__send__(method) do |cond|
              r = cond.kind_of?(Regexp) ? @obj[key].match(cond) \
                                        : (@obj[key] == cond && cond)
              if r && mash.has_key?(key)
                unless mash[key].kind_of?(Array)
                  mash[key] = [mash[key]]
                end
                mash[key] << r
              elsif r; mash[key] = r
              end
              r
            end
          end
        end
      end

      if la[args]
        r = matchs.compact
        mash.empty? ? r : (r << mash)
      else; false
      end
    end

    def match?(*args)
      self.match(args) ? true : false
    end
  end
end
