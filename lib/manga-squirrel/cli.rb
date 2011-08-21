require 'rubygems'
require 'thor'
require 'resque'
require 'yaml'
require 'manga-squirrel/common'
require 'manga-squirrel/queuer'

module Manga
  module Squirrel
    class CLI < Thor
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

      desc 'cbz series [--out=dir]', 'Builds CBZs for all chapters for the specified series name'
      method_option :out, :default => "."
      def cbz(series)
        Manga::Squirrel::Queuer.queue QueueAction::Archive, {:series=>series.strip, :options=>{:out=>File.expand_path(options[:out])}}
      end

      desc 'fetch [--file=name]', 'Tries to fetch all series listed in filename, skipping any chapters already existing'
      method_option :file, :default => "~/.ms"
      def fetch
        Manga::Squirrel::ConfigFile.parse(options[:file]).each do
          |name, site, raw, out, autocbz, volume, chapter|
          puts "Fetching #{name]} from #{site}"
          begin
            Manga::Squirrel::Queuer.queue QueueAction::Download, [:site=>site, :series=>name, :options=>{:raw=>raw, :out=>out, :autocbz=>autocbz, :volume=>volume, :chapter=>chapter}]
          rescue
            #  puts "ERROR: Failed to fetch #{name}\n#{$0} #{$.}: #{$!}"
          end
        end
        f.close
      end
    end
  end
end
