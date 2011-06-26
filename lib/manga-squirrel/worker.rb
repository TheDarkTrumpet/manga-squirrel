require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'zip/zip'
require 'manga-squirrel/common'

module Manga
  module Squirrel
    class Manga::Squirrel::Worker
      @queue  = 'manga-squirrel'

      def self.perform(action, options)
        options = Hash.transform_keys_to_symbols(options)
        case action
        when QueueAction::Download
          self.doDownload options[:chapter], options[:page], options[:url]
        when QueueAction::Archive
          self.doArchive options[:chapter], options[:outdir]
        end
      end

      def self.doDownload(chapter, page, url)
        doc = Nokogiri::HTML(open(url))

        img = doc.css('#image').attribute('src').value
        ext = img.gsub(/\.*(\.[^\.]*)$/).first

        FileUtils.mkdir_p dir = gendir(chapter)

        system 'curl', img, "-o", File.join(dir, "#{"%03d" % page}#{ext}")
      end

      def self.doArchive(chapter, out)
        dir = File.join(out, chapter)

        if not File.directory?(File.join(out,File.dirname(chapter))) then
          FileUtils.mkdir_p File.join(out,File.dirname(chapter))
        end

        if File.exists?(dir+".cbz") then
          File.delete(dir+".cbz")
        end

        Zip::ZipFile.open(dir+".cbz", Zip::ZipFile::CREATE) { 
          |zipfile|
          Dir.glob(File.join(chapter, "*")).sort.each { 
            |file|
            zipfile.add(File.basename(file),file)
          }
        }
      end
    end
  end
end
