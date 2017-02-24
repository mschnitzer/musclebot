require "thread"
require "json"

module Settings
  @@settings = JSON.parse(File.open("#{Dir.pwd}/settings.json", "r").read)
  @@lock = Mutex.new

  @@working_dir = File.expand_path(File.dirname(__FILE__))

  def self.get
    values = nil
    @@lock.synchronize {
      values = @@settings
    }

    values
  end

  def self.working_dir
    @@working_dir
  end
end

