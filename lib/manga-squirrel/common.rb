require 'fileutils'
require 'manga-squirrel/mangafox'
require 'manga-squirrel/mangareader'

def gendir(chapter)
  File.join(File.expand_path("."), chapter[:series].sanitize, "#{[chapter[:volume], "#{"%03d" % chapter[:chapter]}"].compact.join('-')} #{chapter[:caption].sanitize}")
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
    self.gsub(/[\\\?%:|"<>\*]/, '').gsub(/\\/,'-')
  end
end

class Hash
  def self.transform_keys_to_symbols(value)
    return value if not value.is_a?(Hash)
    hash = value.inject({}){|memo,(k,v)| memo[k.to_sym] = Hash.transform_keys_to_symbols(v); memo}
    return hash
  end
end
