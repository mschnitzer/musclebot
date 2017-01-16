require "thread"
require "json"
require "./exception.rb"

class Database
  def initialize(file)
    @db_file = file
    @lock = Mutex.new
    @entries = {}
    @random = Random.new
    @last_messages = {}
    @last_reload = 0

    reload
  end

  def reload(force=false)
    if force == false && @last_reload+5 > Time.now.to_i
      return false
    end

    @last_reload = Time.now.to_i

    @lock.synchronize {
      @entries = JSON.parse(File.open(@db_file, "r").read)
    }

    true
  end

  def random_message(received_message)
    target = nil
    message = nil

    @lock.synchronize {
      command = received_message.split[0..1].join(" ").sub(" ", "_")

      if !@entries[command]
        command = received_message.split[0]
      end

      if !@entries[command]
        raise CommandNotFoundException.new
      else
        length = @entries[command].length
        params = received_message[command.length+1..-1].split(" ")

        # if there are more than one pre defined messages, generate a random one
        # and prevent using the same message twice
        if length > 1
          while true do
            msg = @entries[command][@random.rand(length)]
            
            if !@last_messages[command] || @last_messages[command] != msg
              message = msg
              @last_messages[command] = msg
              break
            end
          end
        else
          message = @entries[command][0]
        end

        target = params[0]
        puts params

        names = message.scan(/\$name(\d+)/)
        names.each do |name|
          name = name[0].to_i
          if params[name-1]
            message = message.sub("$name#{name}", params[name-1])
          end
        end
      end
    }

    { target: target, message: message }
  end

  def add_command(command)
    messages = {}
    @lock.synchronize {
      messages = JSON.parse(File.open(@db_file, "r").read)
    }

    if messages[command]
      raise CommandAlreadyAddedException.new
    end

    messages[command] = []
    @lock.synchronize {
      File.open(@db_file, "w") { |file| file.write(JSON.pretty_generate(messages)) }
    }

    reload(true)
    nil
  end

  def add_message(command, text)
    messages = {}
    @lock.synchronize {
      messages = JSON.parse(File.open(@db_file, "r").read)
    }

    if command.is_a?(Array)
      command = command.join("_")
    end

    if !messages[command]
      raise CommandNotFoundException.new
    end

    if messages[command].index(text)
      raise MessageAlreadyAddedException.new
    end

    messages[command].push(text)
    @lock.synchronize {
      File.open(@db_file, "w") { |file| file.write(JSON.pretty_generate(messages)) }
    }

    reload(true)
    nil
  end
end

