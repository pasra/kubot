# vim: filetype=ruby

guard 'rspec', version: 2, cli: '--drb --color' do
  watch(%r{^(spec/.+_spec\.rb)$}){|m| m[1] }
  watch(%r{^lib/(.+)\.rb$}){|m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { "spec" }
end

