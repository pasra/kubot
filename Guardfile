# vim: filetype=ruby

guard 'rspec', version: 2, cli: '--color' do
  watch(%r{^(spec/.+_spec\.rb)$}){|m| m[1] }
  watch(%r{^lib/(.+)\.rb$}){|m| "spec/#{m[1].sub(/^kubot\//,'')}_spec.rb" }
  watch('spec/spec_helper.rb') { "spec" }
end

