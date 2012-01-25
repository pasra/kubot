module Kubot
  class Adapter
    def initialize(options={})
      @opened = false
      @hooks = []
      @options = {}
    end

    def hook(&block)
      @hooks << block
      self
    end

    def fire event, obj={}
      @hooks.each do |hook|
        hook[event,obj]
      end
      self
    end

    def open
      fire :open
      @opened = true
      self
    end

    def close
      if @opened
        fire :close
        @opened = false
      else
        raise NotOpened
      end
      self
    end

    def say(room,voice,options={})
      raise NotOpened unless @opened
      self
    end

    class NotOpened < StandardError; end
  end
end
