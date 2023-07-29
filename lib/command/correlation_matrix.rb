class ScryingOrb::Command::CorrelationMatrix
  include ScryingOrb::Command

  command 'correlation-matrix'

  calling_convention(0) do
    self.banner = 'Usage: correlation-matrix [options]'
  end

  run do |options:, arguments:|
  end
end
