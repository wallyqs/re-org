require 'erb'
require 'fileutils'

module ReOrg
  class Command
    def initialize(options)
      @options = options
      @org = { }
    end

    def execute!
      case true
      when @options['setup'] 
        prepare_directories
      when @options['new']
        new_file
      when @options['everything']
        reorganize_everything
      end
    end

    def new_file
      prepare_directories

      @org[:title]    = @options["--title"] || 'Untitled'
      @org[:time]     = Time.now
      @org[:type]     = @options["<template>"]      
      @org[:filename] = Time.at(@org[:time]).strftime("#{fix_title(@org[:title])}-%Y-%m-%d-%s")
      @org[:file]     = File.expand_path(File.join(@org[:current_dir], "#{@org[:filename]}.org"))

      c = 1
      while File.exists?(@org[:file])
        c += 1
        @org[:filename] = Time.at(@org[:time]).strftime("%Y-%m-%d-%s-#{c}")
        @org[:file]     = File.expand_path(File.join(@org[:current_dir], "#{@org[:filename]}.org"))
      end

      @org[:org_date] = Time.at(@org[:time]).strftime("[%Y-%m-%d %a]")
      template =  @options["<template>"] || 'writing'

      template_file = File.expand_path("templates/#{template}.org", File.dirname(__FILE__))
      if not File.exists?(template_file)
        puts "Could not find template `#{template}.org' at #{template_file}".red
        exit 1
      end
      template = File.open(template_file).read
      content = ERB.new(template).result(binding)

      File.open(@org[:file], 'w') {|f| f.puts content }
      puts "Created a new writing at `#{@org[:file]}'".green
    end

    def fix_title(title)
      return nil unless title
      title.gsub(/[\s.\/\\]/, '-').downcase
    end

    def prepare_directories
      current_dir = File.expand_path('./current', File.dirname('.'))
      if not File.exists?(current_dir)
        puts "Creating working dir at `#{current_dir}'".green
        FileUtils.mkdir(current_dir)
      end

      @org[:current_dir] = current_dir
    end
  end
end
