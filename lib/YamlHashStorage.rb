# encoding: UTF-8

require 'yaml'
require 'forwardable'

class YamlHashStorage

  extend Forwardable
  def_delegators :@data, :[], :keys, :values, :fetch, :invert

  def initialize(path)
    @path = path
    if File.exist? @path
      load
    else
      @data = {}
    end
  end

  def load
    @data = File.open(@path, 'rb') { |file| YAML.load(file) }
  end
  def save
    File.open(@path, 'wb') { |file| YMAL.dump(@data, file) }
  end

  def [](k)
    @data[k]
  end

  def []=(k, v)
    @data[k] = v
    save
  end

end

# x = MarhsalledHashStorage.new("/tmp/foo.txt")
# x[2] = 8
# 
# y = MarhsalledHashStorage.new("/tmp/foo.txt")
# puts y[2]
