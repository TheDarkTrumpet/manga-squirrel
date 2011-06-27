require 'fileutils'
require 'manga-squirrel/mangafox'

module Manga
  module Squirrel
    module QueueAction
      Download = 0
      Archive = 1
    end
  end
end

def namesanitize(name)
  name.gsub(/[\\\?%:|"<>]/, '')
end

def gendir(chapter)
  File.join(chapter[:root], chapter[:series], "#{[chapter[:volume], chapter[:chapter]].compact.join('-')} #{namesanitize(chapter[:caption])}")
end

class String
  def to_class
    chain = self.split "::"
    klass = Kernel
    chain.each do |klass_string|
      klass = klass.const_get klass_string
    end
    klass.is_a?(Class) ? klass : nil
  rescue NameError
    nil
  end
end

class Hash
  def self.transform_keys_to_symbols(value)
    return value if not value.is_a?(Hash)
    hash = value.inject({}){|memo,(k,v)| memo[k.to_sym] = Hash.transform_keys_to_symbols(v); memo}
    return hash
  end
end
