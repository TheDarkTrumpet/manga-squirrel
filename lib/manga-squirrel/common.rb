require 'fileutils'
require 'manga-squirrel/mangafox'
require 'manga-squirrel/mangareader'
require 'manga-squirrel/redhawk'
require 'uri'

def gendir(raw, chapter)
  File.join(raw, chapter[:series].to_s.sanitize, "#{[chapter[:volume], "#{outNum chapter[:chapter]}"].compact.join('-')} #{chapter[:caption].to_s.sanitize}")
end

def outNum (num)
  return "%03d" % num if num.to_i == num
  "%05.1f" % num
end

def bundlePath (root, chapter, cbf)
  "#{gendir root, chapter}.#{cbf}"
end

def processDownload(page, options)
  doc = Nokogiri::HTML(open(URI.encode(page[:url])))
  img = doc.css(options[:chapter][:img_div]).attribute('src').value
  ext = img.gsub(/\.*(\.[^\.]*)$/).first
  return img, ext
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
