class ScryingOrb::Command::FeeReport
  include ScryingOrb::Command

  command 'fee-report'

  calling_convention(1) do
    self.banner = 'Usage: fee-report [options] <channel ID>'
  end

  run do |options:, arguments:|
  end
end
