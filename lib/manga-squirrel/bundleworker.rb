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

        file = genoutname(chapter options[:cbf])
        FileUtils.mkdir_p(File.dirname(file)) unless File.directory?(File.dirname(file))

        File.delete(file) if File.exists?(file)

        if options[:cbf] == "cbz" then
          Zip::ZipFile.open(file, Zip::ZipFile::CREATE) do 
            |zipfile|
            puts Dir.entries(dir).inspect
            Dir.entries(dir).grep(/^[^.]/).sort.each do 
              |file|
              zipfile.add(File.basename(file), File.join(dir, file))
            end
          end
        end
      end
    end
  end
end
