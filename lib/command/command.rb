require 'optparse'

module ScryingOrb::Command
  @commands = []

  def self.start_command
    command_name = ARGV.first
    show_default_help if command_name.nil?

    command = @commands.select { |command| command.name == command_name }.first
    no_command_found if command.nil?

    ScryingOrb.log.debug("Running command #{command}")

    command.start!
  end

  def self.show_default_help
    @commands.each do |command|
      puts command.instance_variable_get(:@optparse).help
      puts
    end

    exit 0
  end

  def self.no_command_found
    ScryingOrb.log.error("No command found (expected one of; #{@commands.map(&:name).join(', ')})")

    raise "No command found"
  end

  def self.included(base)
    ScryingOrb.log.debug("Loading command #{base}")

    @commands.append(base)

    base.extend CommandName
    base.extend CallingConvention
    base.extend Runner
  end

  module CommandName
    @command_name = nil

    def command(name)
      @command_name = name
    end

    def name
      @command_name
    end
  end

  module CallingConvention
    @arity = nil
    @optparse = nil

    def calling_convention(arity, &block)
      raise "block not given" unless block_given?

      @arity = arity

      @optparse = OptionParser.new
      @optparse.instance_exec(&block)
      @optparse.instance_exec do
        @options = {}

        def options
          @options
        end
      end
    end

    def parse_options!
      @optparse.parse!
      @optparse.options
    end

    def arguments!
      ARGV[1..-1].tap do |arguments|
        case @arity
        when Integer
          raise "requires #{@arity} argument(s)" unless @arity == arguments.count
        when Range
          raise "requires #{@arity} argument(s)" unless @arity.include? arguments.count
        else
          raise 'calling convention for arity must be described as a number or range'
        end
      end
    end
  end

  module Runner
    @block = nil

    def start!
      invoke(options: parse_options!, arguments: arguments!)
    end

    def invoke(options:, arguments:)
      instance_exec(options: options, arguments: arguments, &@block)
    end

    def run(&block)
      raise "block not given" unless block_given?

      @block = block
    end
  end
end

Dir[File.join(__dir__, '*.rb')].delete_if { |path| File.basename(path) == File.basename(__FILE__) }.each do |command_script|
  ScryingOrb.log.debug("Loading command script #{command_script}")
  load command_script
end

