require 'erb'
require 'fileutils'
require 'org-ruby'

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
      when @options['by']
        reorganize_everything
      end
    end

    def new_file
      prepare_directories

      @org[:title]    = @options["--title"] || 'Untitled'
      @org[:template] = @options["<template>"]
      @org[:notebook] = guess_notebook
      @org[:time]     = Time.now
      @org[:filename] = resolve_filename
      @org[:date]     = Time.at(@org[:time]).strftime("[%Y-%m-%d %a]")
      @org[:file]     = File.expand_path(File.join(@org[:current_dir], "#{@org[:filename]}.org"))

      c = 1
      while File.exists?(@org[:file])
        c += 1
        @org[:filename] = Time.at(@org[:time]).strftime("%Y-%m-%d-%s-#{c}")
        @org[:file]     = File.expand_path(File.join(@org[:current_dir], "#{@org[:filename]}.org"))
      end
      template =  @org[:template] || 'writing'
      template_file = File.expand_path("templates/#{template}.org", File.dirname(__FILE__))
      if not File.exists?(template_file)
        puts "Could not find template `#{template}.org' at #{template_file}".red
        exit 1
      end
      template = File.open(template_file).read
      content = ERB.new(template).result(binding)

      File.open(@org[:file], 'w') {|f| f.puts content }
      puts content.yellow if ENV['DEBUG']
      puts "Created a new writing at `#{@org[:file]}'".green
    end

    private
    def slugify(name)
      return nil unless name
      name.gsub(/[\s.\/\\]/, '-').downcase
    end

    def guess_notebook
      @options["--notebook"] || File.basename(File.expand_path('.'))
    end

    def resolve_filename
      slug = slugify(@org[:notebook] || @org[:title])
      Time.at(@org[:time]).strftime("#{slug}-%s")
    end

    def prepare_directories
      current_dir = File.expand_path('./orgs/current', File.dirname('.'))
      if not File.exists?(current_dir)
        puts "Creating working dir at `#{current_dir}'".green
        FileUtils.mkdir(current_dir)
      end

      @org[:current_dir] = current_dir
    end
  end
end
