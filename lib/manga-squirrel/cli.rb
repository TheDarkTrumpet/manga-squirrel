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
        self.makequeue series, options
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

      desc 'buildcbz series [--out=dir]', 'Builds CBZs for all chapters for the specified series name'
      method_option :out, :default => "."
      def buildcbz(series)
		if not File.directory?(File.join(options[:out], series)) then
		  Dir.mkdir(File.join(options[:out], series))
		end

        Dir.glob(File.join(series,"*")).each {
          |chapter|
          Manga::Squirrel::Worker.makecbz(chapter,options[:out])
          puts "Built #{chapter}\n"
        }
      end

      desc 'fetch [--file=name]', 'Tries to fetch all mangas listed in filenaem, skipping any chapters already existing'
method_option :file, :default => ".ms"
      def fetch
        begin
          f = File.open(options[:file], 'r')
        rescue
          puts "ERROR: File #{options[:file]} not found"
          return
        end
        f.readlines.each {
          |name|
          puts "Fetching #{name}"
          begin
            self.makequeue name.strip, {:volumes=>"true",:chapters=>"true"}
          rescue
            puts "ERROR: Failed to fetch #{name}"
          end
        }
        f.close
      end

      desc 'rename series', '**For upgrading between MS versions. Sanitizes all chapter names'
      def rename(series)
        Dir.glob(File.join(series,"*")).each {
          |chapter|
          if File.directory?(chapter) then
            new_name = Manga::Squirrel::Worker::namesanitize(chapter)
			unless new_name == chapter then
              puts "Renamed #{chapter} to #{new_name}"
              File.rename(chapter,new_name)
			end
          end
        }
      end

      no_tasks do
        def makequeue(series, options)
            Manga::Squirrel::Downloader.queue series.downcase.gsub(/[^\w -]/,"").gsub(/[ -]/,"_"), options
        end
      end
    end
  end
end
