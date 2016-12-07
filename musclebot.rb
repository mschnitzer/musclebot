#!/usr/bin/ruby
require "json"
require "cinch"
require "./database.rb"
require "./exception.rb"

settings = JSON.parse(File.open("./settings.json", "r").read)
database = Database.new("./messages.json")

bot = Cinch::Bot.new do
  configure do |c|
    c.server = settings["server"]
    #c.port = settings["port"].to_i
    c.nick = settings["botname"]
    c.channels = [settings["channel"]]
  end
  
  on :message, /.+/ do |message|
    text = message.params[1]
    if text
      if text[0] == "!" && text.length >= 2
        text = text[1..-1]
        message_parts = text.split

        if text == "reload"
          if database.reload
            message.reply "#{message.user.nick}: Dange... Du dapp!"
          else
            message.reply "#{message.user.nick}: Ich wuerd halt a mal an moment wadden!"
          end
        else
          if message_parts[1] == "add"
            begin
              database.add_message(message_parts[0], message_parts[2..-1].join(" "))
              message.reply "#{message.user.nick}: Dange!"
            rescue CommandNotFoundException
              message.reply "#{message.user.nick}: Was willst du da hinzufuegen?! Den command gibts netmal..."
            rescue MessageAlreadyAddedException
              message.reply "#{message.user.nick}: Herrje... Die nachricht gibts doch scho laengst... erfind mal was neues... trottel..."
            end
          elsif message_parts[2] == "add"
            begin
              database.add_message(message_parts[0..1], message_parts[3..-1].join(" "))
              message.reply "#{message.user.nick}: Dange!"
            rescue CommandNotFoundException
              message.reply "#{message.user.nick}: Was willst du da hinzufuegen?! Den command gibts netmal..."
            rescue MessageAlreadyAddedException
              message.reply "#{message.user.nick}: Herrje... Die nachricht gibts doch scho laengst... erfind mal was neues... trottel..."
            end
          else
            target = text.split.last
            
            if text == target
              target = message.user.nick
            end

            random_message = database.random_message(text)
            if !random_message
              message.reply "#{message.user.nick}: du full-dapp! den command gibbet net!"
            else
              message.reply "#{target}: #{random_message}"
            end
          end
        end
      end
    end
  end
end

bot.start

