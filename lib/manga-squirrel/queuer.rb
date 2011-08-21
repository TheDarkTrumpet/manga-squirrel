require 'rubygems'
require 'fileutils'
require 'resque'
require 'manga-squirrel/common'
require 'manga-squirrel/downloadworker'
require 'manga-squirrel/bundleworker'

module Manga
  module Squirrel
    class Manga::Squirrel::Queuer
      def self.queueDownload(site, series, options)        
        seriesSan = site::urlify(series)

        existingChapters = self.getExisting(series)
        chapters = site::getChapters(seriesSan, options, existingChapters)

        if chapters.nil? then
          puts "ERROR: no chapters retrieved"
          return
        end

        dlChapters = []
        series.chapters.each_value do
          |chapter|
          if existingChapters.include?(chapter[:chapter])
            next
          end
          Resque.enqueue(Manga::Squirrel::DownloadWorker, chapter)
        end
      end

      def self.queueBundle(series)
        Dir.glob(File.join(series,"*")).each do
          |chapter|

          if File.exists? File.join(options[:out],series,chapter+".cbz") and not options[:force] then
            next
          end 

          puts "QUEUE-CBZ: #{chapter}..."

          Resque.enqueue(
            Manga::Squirrel::BundleWorker, {:root=>File.expand_path("."), :chapter=>chapter, :outdir=>options[:out]}
          )
        end
      end

      private
      def self.getExisting(series)
        existingChapters = Array.new
        Dir.glob(File.join(series,"*")).each do
          |chapter|
          existingChapters.push revgendir(chapter)[:chapter].to_f
        end
        existingChapters
      end
    end
  end
end
