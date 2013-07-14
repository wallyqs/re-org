module ReOrg
  class Command
    def initialize(cmd_options)
      @cmd = cmd_options
    end

    def execute!
      # Execute the command according to the settings
      puts "Now somethig will be executed".green
      p @cmd
    end
  end
end
