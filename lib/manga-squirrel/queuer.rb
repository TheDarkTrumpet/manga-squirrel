require 'rubygems'
require 'fileutils'
require 'resque'
require 'manga-squirrel/common'
require 'manga-squirrel/worker'

module Manga
  module Squirrel
    class Manga::Squirrel::Queuer
      def self.queue(action, options)
        case action
        when QueueAction::Download
          self.queueDownload options[:site], options[:series], options[:options]
        when QueueAction::Archive
          self.queueArchive options[:series], options[:options]
        end
      end

      private

      def self.queueDownload(site, series, options)        
        seriesSan = series.downcase.gsub(/[^\w -]/,"").gsub(/[ -]/,"_")

        path = gendir({:series=>series, :volume=>"*", :chapter=>"*", :caption=>"*"});
        existingChapters = Array.new
        Dir.glob(path).each {
          |chapter|
          existingChapters.push chapter.split(/(.*)\/([0-9]+)-([0-9.]+) (.*)/)[3].to_f
        }
        
        chapters = site::getChapters(seriesSan, options, existingChapters)

        if chapters.nil? then
          puts "ERROR: no chapters retrieved"
          return
        end

        chapters.each {
          |chapter|
          path = gendir(chapter) 

          1.upto(chapter[:pages]) {
            |page|
            page_url = site::getPageURL(chapter, page)

            Resque.enqueue(
              Manga::Squirrel::Worker,
              QueueAction::Download, {:chapter=>chapter, :page=>page, :url=>page_url}
            )
          }
        }
      end

      def self.queueArchive(series, options)
        Dir.glob(File.join(series,"*")).each {
          |chapter|

          puts "QUEUE-CBZ: #{chapter}..."

          Resque.enqueue(
            Manga::Squirrel::Worker,
            QueueAction::Archive, {:chapter=>chapter, :outdir=>options[:outdir]}
          )
        }
      end
    end
  end
end
