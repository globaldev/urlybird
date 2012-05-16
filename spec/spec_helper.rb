$:.unshift(File.expand_path('../lib',__FILE__))

require 'rspec'

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
  add_filter 'vendor'
end

require 'urlybird'

# String helper for large text-inserts
class String
  def undent
    gsub /^.{#{slice(/^ +/).length}}/, ''
  end
end
