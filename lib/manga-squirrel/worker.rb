require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'zip/zip'

module Manga
  module Squirrel
    class Worker
      @queue  = 'manga-squirrel'

      def self.gendir(series, volume, chapter, caption)
        return File.join(series, "#{[volume, chapter].compact.join('-')} #{caption}")
      end

      def self.perform(series, volume, chapter, caption, page, url, pages)
        doc = Nokogiri::HTML(open(url))

        img = doc.css('#image').attribute('src').value
        ext = img.gsub(/\.*(\.[^\.]*)$/).first

        FileUtils.mkdir_p dir = self.gendir(series, volume, chapter, caption)

        system 'curl', img, "-o", File.join(dir, "#{"%03d" % page}#{ext}")
		if page == pages then
          while Dir.glob(File.join(dir, "*").count) < pages
            sleep 1
            puts "Worker paused - not all content downloaded to #{series} #{volume} #{chapter}\n"
          end
          self.makecbz(dir)
        end
      end

      def self.makecbz(dir)
        if File.exists?(dir+".cbz") then
          File.delete(dir+".cbz")
        end

        Zip::ZipFile.open(dir+".cbz", Zip::ZipFile::CREATE) { 
          |zipfile|
          Dir.glob(File.join(dir, "*")) { 
            |file|
            zipfile.add(File.basename(file),file)
          }
        }
      end
    end
  end
end
