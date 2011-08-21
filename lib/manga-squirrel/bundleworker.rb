require 'rubygems'
require 'fileutils'
require 'zip/zip'
require 'manga-squirrel/common'
require 'peach'

module Manga
  module Squirrel
    class Manga::Squirrel::BundleWorker
      @queue  = 'manga-squirrel'

      def self.perform(action, chapter)
        chapter = Hash.transform_keys_to_symbols(chapter)

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
