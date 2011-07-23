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
          self.doArchive options[:root], options[:chapter], options[:outdir]
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

      def self.doArchive(root, chapter, out)
        dir = File.join(out, chapter)

        if not File.directory?(File.join(out,File.dirname(chapter))) then
          FileUtils.mkdir_p File.join(out,File.dirname(chapter))
        end

        if File.exists?(dir+".cbz") then
          File.delete(dir+".cbz")
        end

        Zip::ZipFile.open(dir+".cbz", Zip::ZipFile::CREATE) { 
          |zipfile|
          puts Dir.entries(File.join(root,chapter)).inspect
          Dir.entries(File.join(root, chapter)).grep(/^[^.]/).sort.each { 
            |file|
            zipfile.add(File.basename(file), File.join(root, chapter, file))
          }
        }
      end
    end
  end
end
