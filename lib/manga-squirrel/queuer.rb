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
          self.queueArchive options[:series], options[:options]
        end
      end

      private

      def self.queueDownload(series)        
        existingChapters = []
        Dir.glob(File.join(series.series,"*")).each {
          |chapter|
          existingChapters.push revgendir(chapter)[:chapter].to_f
        }

        dlChapters = []
        series.chapters.each_value {
          |chapter|
          if existingChapters.include?(chapter[:chapter])
            next
          end
          Resque.enqueue(Manga::Squirrel::Worker, QueueAction::Download, chapter)
        }
      end

      def self.queueArchive(series, options)
        Dir.glob(File.join(series,"*")).each {
          |chapter|

          puts "QUEUE-CBZ: #{chapter}..."

          Resque.enqueue(
            Manga::Squirrel::Worker,
            QueueAction::Archive, {:root=>File.expand_path("."), :chapter=>chapter, :outdir=>options[:out]}
          )
        }
      end
    end
  end
end
