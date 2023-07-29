module ScryingOrb::Configuration::Lncli
  include ScryingOrb::Configuration

  file 'lncli.yaml'

  def self.global_options
    return @arguments unless @arguments.nil?

    @arguments =
      if configuration.nil?
        nil
      else
        options = configuration['options']
        unless options.is_a?(String) || (options.is_a?(Enumerable) && options.all? { |option| option.is_a?(String) })
          raise 'expected a string or list of strings for configuration'
        end

        [*options]
      end
  end
end
