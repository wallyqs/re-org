require 'erb'
require 'fileutils'

module ReOrg
  class Command
    def initialize(options)
      @options = options
      @org = { }
    end

    def execute!
      case
      when @options['new'] == true
        new_file
      when @options['completed'] == true
        completed
      end
    end

    def new_file
      prepare_run

      @org[:org_date] = Time.at(@org[:time]).strftime("[%Y-%m-%d %a]")
      @org[:title] = @options["title"] || "Untitled"
      template =  @options["<name>"] || 'writing'

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

    def prepare_run
      current_dir = File.expand_path('../current')
      if not File.exists?(current_dir)
        puts "Creating current dir at `#{current_dir}'".green
        FileUtils.mkdir(current_dir)
      end

      @org[:current_dir] = current_dir
      @org[:time]     = Time.now
      @org[:filename] = Time.at(@org[:time]).strftime("%Y-%m-%d-%s")
      @org[:file]     = File.expand_path(File.join(@org[:current_dir], "#{@org[:filename]}.org"))

      c = 1
      while File.exists?(@org[:file])
        c += 1
        @org[:filename] = Time.at(@org[:time]).strftime("%Y-%m-%d-%s-#{c}")
        @org[:file]     = File.expand_path(File.join(@org[:current_dir], "#{@org[:filename]}.org"))
      end
    end
  end
end
