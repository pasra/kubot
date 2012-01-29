source "http://rubygems.org"

group :test do
  gem "rspec"
  gem "guard-rspec"
  case RUBY_PLATFORM
  when /darwin/i
    gem "rb-fsevent"
  when /linux/i
    gem "rb-inotify"
  end
end

# Specify your gem's dependencies in kubot.gemspec
gemspec
