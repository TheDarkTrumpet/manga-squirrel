require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'zip/zip'
require 'manga-squirrel/common'

module Manga
  module Squirrel
    class Worker
      @queue  = 'manga-squirrel'

      def self.perform(action, options)
        case action
        when QueueAction::Download
          self.doDownload options[:chapter], options[:page], options[:url]
        when QueueAction::Archive
          self.doArchive options[:chapter], options[:outdir]
        end

      def self.doDownload(chapter, page, url)
        doc = Nokogiri::HTML(open(url))

        img = doc.css('#image').attribute('src').value
        ext = img.gsub(/\.*(\.[^\.]*)$/).first

        FileUtils.mkdir_p dir = self.gendir(chapter)

        system 'curl', img, "-o", File.join(dir, "#{"%03d" % page}#{ext}")
      end

      def self.doArchive(chapter, out)
        dir = gendir(chapter)

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
