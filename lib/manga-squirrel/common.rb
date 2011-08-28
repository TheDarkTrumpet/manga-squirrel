require 'fileutils'
require 'manga-squirrel/mangafox'
require 'manga-squirrel/mangareader'

def gendir(raw, chapter)
  File.join(raw, chapter[:series].sanitize, "#{[chapter[:volume], "#{"%03d" % chapter[:chapter]}"].compact.join('-')} #{chapter[:caption].sanitize}")
end

def genoutname(chapter, cbf)
  File.join(chapter[:out], chapter[:series].sanitize, (chapter[:caption].sanitize + "." + cbf))
end

#Within limits reverses the gendir procedure
def revgendir(filename)
  chapter = {}
  try = filename.split(/(.*)\/([0-9]+)-([0-9.]+) (.*)/)
  if try[3].nil? then
    try = filename.split(/(.*)\/([0-9.]+) (.*)/)
    chapter[:series] = try[1]
    chapter[:volume] = nil
    chapter[:chapter] = try[2].to_f
    chapter[:caption] = try[3]
  else
    chapter[:series] = try[1]
    chapter[:volume] = try[2]
    chapter[:chapter] = try[3].to_f
    chapter[:caption] = try[4]
  end

  chapter
end

class String
  def sanitize
    self.gsub(/[\?%:|"<>\*]/, '').gsub(/[\\\/]/,'-')
  end
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
