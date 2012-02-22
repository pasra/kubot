module Kubot
  class Manager
    @@bots = {}

    def initialize(load_path)
      @load_path = load_path
      @timestamps = {}
      @bot = {}
      @bot_name = {}
    end

    def load(name, config={}, option={})
      if @bot_name[name]
        self.reload name, *@bot_name[name][:args]
        return
      end

      path = locate(name)
      raise BotNotFound unless path
      bots = load_(name,path)
      bots.each do |bot|
        @bot[bot] = bot.new(config, option)
      end
      @bot_name[name] = {args: [config, option], path: path}
    end

    def load_(name,path)
      diff = Kubot::Bot.bots_diff { Kernel.load(path) }
      @timestamps[name] = File.mtime(path)
      @@bots[name] ||= []
      @@bots[name].push *diff
      @@bots[name].uniq!
      @@bots[name]
    end

    def unload(name)
      raise BotNotLoaded unless @bot_name[name]
      @@bots[name].each do |bot_klass|; bot = @bot[bot_klass]
        bot.finalize if bot.respond_to?(:finalize)
        @bot.delete bot_klass
      end
      @bot_name.delete name
    end

    def reload(*args)
      if args.empty?
        @bot_name.each do |k,v|
          if @timestamps[k] < File.mtime(v[:path])
            reload_(k, *v[:args])
          end
        end
      else
        reload_ *args
      end
    end

    def reload_(name, config={}, option={})
      bots = ->(block) do
        (@@bots[name] || []).each do |bot_klass|
          block[@bot[bot_klass]]
        end
      end

      bots[->(bot) { bot.before_reload if bot.respond_to?(:before_reload) }]
      begin
        self.unload(name)
      rescue BotNotLoaded; end
      self.load(name, config, option)
      bots[->(bot) { bot.after_reload if bot.respond_to?(:after_reload) }]
    end

    def locate(name)
      _ = nil
      load_path.each do |path|
        _ = Dir["#{path}/#{name}.rb"][0]
        break if _
      end
      _
    end

    def unload_all
      @bot_name.keys.each {|key| unload(key) }
    end

    class BotNotFound < Exception; end
    class BotNotLoaded < Exception; end

    attr_reader :load_path
  end
end
