# encoding: UTF-8

require 'yaml'
require 'forwardable'

class YamlHashStorage

  extend Forwardable
  attr_reader :data
  def_delegators :@data, :keys, :values, :fetch, :invert

  def initialize(path, default)
    @default = default
    @path = path
    if File.exist? @path
      load
    else
      @data = {}
    end
  end

  def load
    @data = File.open(@path, 'rb') { |file| YAML.load(file) } || {}
  end
  def save
    File.open(@path, 'wb') { |file| YAML.dump(@data, file) }
    puts "saved"
  end

  def [](k)
    @data[k] = @default.call unless @data[k]
    @data[k]
  end

  def []=(k, v)
    @data[k] = v
    save
  end

end

# x = YamlHashStorage.new("/tmp/foo.txt", lambda {|| nil})
# x[2] = 8
# 
# y = YamlHashStorage.new("/tmp/foo.txt", lambda {|| nil})
# puts y[2]
