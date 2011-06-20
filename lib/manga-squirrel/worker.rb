require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'zip/zip'

module Manga
  module Squirrel
    class Worker
      @queue  = 'manga-squirrel'
	
      def self.namesanitize(name)
        name.gsub(/[\\\?%*|"<>]/, '')
      end

      def self.gendir(series, volume, chapter, caption)
        return File.join(series, "#{[volume, chapter].compact.join('-')} #{self.namesanitize caption}")
      end

      def self.perform(series, volume, chapter, caption, page, url, pages)
        doc = Nokogiri::HTML(open(url))

        img = doc.css('#image').attribute('src').value
        ext = img.gsub(/\.*(\.[^\.]*)$/).first

        FileUtils.mkdir_p dir = self.gendir(series, volume, chapter, caption)

        system 'curl', img, "-o", File.join(dir, "#{"%03d" % page}#{ext}")
      end

      def self.makecbz(dir,out)
        if File.exists?(File.join(out, dir+".cbz")) then
          File.delete(File.join(out, dir+".cbz"))
        end

        Zip::ZipFile.open(File.join(out, dir+".cbz"), Zip::ZipFile::CREATE) { 
          |zipfile|
          Dir.glob(File.join(dir, "*")).sort.each { 
            |file|
            zipfile.add(File.basename(file),file)
          }
        }
      end
    end
  end
end
