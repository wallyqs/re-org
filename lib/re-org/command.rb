require 'erb'
require 'fileutils'
require 'org-ruby'

module ReOrg

  TODO_ORGS_DIR = 'todo'
  DONE_ORGS_DIR = 'done'

  class Command
    def initialize(options)
      @options = options
    end

    def execute!
      case true
      when @options['new']
        new_file
      when @options['status']
        show_status
      end
    end

    def show_status
      puts "============ CURRENT STATUS ============"
      summary = Hash.new { |h,k| h[k] = {} }

      org_files = Dir["#{@org[:path]}/#{TODO_ORGS_DIR}/*"]
      org_files.each do |org_file|
        org_content = Orgmode::Parser.new(File.open(org_file).read)
        if org_content.in_buffer_settings["NOTEBOOK"]
          notebook_name = org_content.in_buffer_settings["NOTEBOOK"]
          summary[notebook_name][:texts]    ||= []
          summary[notebook_name][:keywords] ||= {}
          summary[notebook_name][:texts] << org_content
          keywords = org_content.headlines.map { |h| h.keyword }
          keywords.each do |k|
            summary[notebook_name][:keywords][k] ||= 0
            summary[notebook_name][:keywords][k]  += 1
          end
        else
          puts "Org file without notebook defined: #{org_file}".yellow
        end
      end

      summary.each_pair do |notebook, info|
        puts "#{info[:texts].count} org files for '#{notebook}' notebook.".green
        info[:keywords].each do |keyword, count|
          keyword ||= 'NONE'
          puts "#{keyword}: #{count}"
        end if @options["--count-keywords"]
        info[:texts].each { |o| puts ["\t", o.headlines.first].join('')}
      end
    end

    def new_file
      @org = OrgFile.new({ :title => @options["--title"],
                           :template => @options["<template>"],
                           :notebook => @options["<notebook>"] || @options["--notebook"],
                           :path => @options["--path"]
                         })

      c = 1
      while File.exists?(@org[:file])
        c += 1
        @org[:filename] = Time.at(@org[:time]).strftime("%Y-%m-%d-%s-#{c}")
        @org[:file]     = File.expand_path(File.join(@org[:todo_dir], "#{@org[:filename]}.org"))
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
  end
end
