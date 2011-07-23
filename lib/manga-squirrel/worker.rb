require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'zip/zip'
require 'manga-squirrel/common'
require 'peach'

module Manga
  module Squirrel
    class Manga::Squirrel::Worker
      @queue  = 'manga-squirrel'

      def self.perform(action, chapter)
        chapter = Hash.transform_keys_to_symbols(chapter)
        case action
        when QueueAction::Download
          self.doDownload chapter
        when QueueAction::Archive
          self.doArchive chapter
        end
      end

      def self.doDownload(chapter)
        chapter[:pages].peach { 
        |page|
          page = Hash.transform_keys_to_symbols(page)
          doc = Nokogiri::HTML(open(page[:url]))

          img = doc.css(chapter[:img_div]).attribute('src').value
          ext = img.gsub(/\.*(\.[^\.]*)$/).first

          FileUtils.mkdir_p dir = gendir(chapter)

          system 'curl', img, "-o", File.join(dir, "#{"%03d" % page[:num]}#{ext}")
        }
      end

      def self.doArchive(chapter)
        dir = File.join(File.expand_path("."), chapter)
        FileUtils.mkdir_p(File.dirname(dir)) unless File.directory?(File.dirname(dir))

        File.delete(dir+".cbz") if File.exists?(dir+".cbz")

        Zip::ZipFile.open(dir+".cbz", Zip::ZipFile::CREATE) { 
          |zipfile|
          puts Dir.entries(dir).inspect
          Dir.entries(dir).grep(/^[^.]/).sort.each { 
            |file|
            zipfile.add(File.basename(file), File.join(dir, file))
          }
        }
      end
    end
  end
end
