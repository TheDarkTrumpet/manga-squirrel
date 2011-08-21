require 'rubygems'
require 'fileutils'
require 'resque'
require 'manga-squirrel/common'
require 'manga-squirrel/worker'

module Manga
  module Squirrel
    class Manga::Squirrel::Queuer
      def self.queue(action, series)
        case action
        when QueueAction::Download
          self.queueDownload series
        when QueueAction::Archive
          self.queueArchive series
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
          Resque.enqueue(Manga::Squirrel::Worker, QueueAction::Download, chapter)
        end
      end

      def self.queueArchive(series)
        Dir.glob(File.join(series,"*")).each do
          |chapter|

          if File.exists? File.join(options[:out],series,chapter+".cbz") and not options[:force] then
                  next
          end 

          puts "QUEUE-CBZ: #{chapter}..."

          Resque.enqueue(
            Manga::Squirrel::Worker,
            QueueAction::Archive, {:root=>File.expand_path("."), :chapter=>chapter, :outdir=>options[:out]}
          )
        end
      end
    end
  end
end
