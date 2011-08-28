require 'rubygems'
require 'fileutils'
require 'zip/zip'
require 'manga-squirrel/common'
require 'peach'

module Manga
  module Squirrel
    class Manga::Squirrel::BundleWorker
      @queue  = 'manga-squirrel'

      def self.perform(options)
        options = Hash.transform_keys_to_symbols(options)
        chapter = Hash.transform_keys_to_symbols(options[:chapter])


        dir = gendir options[:raw], chapter
        bundle = genoutname chapter, options[:cbf]
        bundledir = File.dirname bundle

        FileUtils.mkdir_p bundledir unless File.directory? bundledir
        File.delete(bundle) if File.exists?(bundle)

        case options[:cbf]
        when "cbz"
          Zip::ZipFile.open(bundle, Zip::ZipFile::CREATE) do
            |zipfile|
            Dir.entries(dir).grep(/^[^.]/).sort.each do
              |image|
              zipfile.add(File.basename(image), File.join(dir, image))
            end
          end
        end
      end
    end
  end
end
