require "thread"
require "json"

module Settings
  @@settings = JSON.parse(File.open("#{Dir.pwd}/settings.json", "r").read)
  @@lock = Mutex.new

  def self.get
    values = nil
    @@lock.synchronize {
      values = @@settings
    }

    values
  end
end

