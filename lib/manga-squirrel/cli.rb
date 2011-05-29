require 'rubygems'
require 'thor'
require 'resque'
require 'manga-squirrel/downloader'

module Manga
  module Squirrel
    class CLI < Thor
      desc 'queue series [ --volumes=filter ] [ --chapters=filter ]', 'Queue the specified manga for download.'
      method_option :volumes, :default => "true"
      method_option :chapters, :default => "true"
      def queue(series)
        Manga::Squirrel::Downloader.queue series.downcase.gsub(/[^a-z0-9]/,"_"), options
      end
  
      desc 'worker', 'Starts a manga-squirrel worker.'
      def worker
        worker = Resque::Worker.new('manga-squirrel')
        worker.verbose = true
        worker.log "Starting Worker #{worker}"

        worker.work(5)
      end

      desc 'workers [ --count=number ]', 'Starts a pool of manga-squirrel worker. The default number is 5.'
      method_option :count, :default => 5
      def workers
        threads = []

        options[:count].to_i.times do
          threads << Thread.new do
            system "manga-squirrel worker"
          end
        end

        threads.each { |thread| thread.join }    
      end

      desc 'rebuildcbz series', 'Rebuilds all CBZs for the specified series name'
      def rebuildcbz(series)
        Dir.glob(File.join(series,"*")).each {
          |chapter|
          Manga::Squirrel::Worker.makecbz(chapter)
          puts "Rebuilt #{chapter}\n"
        }
      end
    end
  end
end
