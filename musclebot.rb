#!/usr/bin/ruby
require "json"
require "cinch"
require "thread"
require "./database.rb"
require "./exception.rb"
require "./settings.rb"
require "./pr0gram.rb"

database = Database.new("./messages.json")

Thread.new do
  while true do
    Pr0gram.refresh
    sleep 60
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = Settings.get["server"]
    #c.port = Settings.get["port"].to_i
    c.nick = Settings.get["botname"]
    c.channels = [Settings.get["channel"]]
  end
  
  on :message, /.+/ do |message|
    text = message.params[1]
    if text
      if text[0] == "!" && text.length >= 2
        text = text[1..-1]
        message_parts = text.split

        if text == "reload"
          if database.reload
            message.reply "#{message.user.nick}: #{Settings.get["messages"]["thanks"]}"
          else
            message.reply "#{message.user.nick}: #{Settings.get["messages"]["please_wait"]}"
          end
        else
          if message_parts[0] == "command" && message_parts[1] == "add"
            begin
              database.add_command(message_parts[2])
            rescue CommandAlreadyAddedException
              message.reply "#{message.user.nick}: #{Settings.get["messages"]["command_already_added"]}"
            end
          elsif message_parts[0] == "pr0"
            data = Pr0gram.random_comment
            comment = data[:comment].sample["content"].strip.gsub("\n", " ").gsub("\r", " ")

            if message_parts[1]
              message.reply "#{message_parts[1]}: #{comment}"
            else
              message.reply "#{message.user.nick}: #{comment}"
            end
          else
            if message_parts[1] == "add"
              begin
                database.add_message(message_parts[0], message_parts[2..-1].join(" "))
                message.reply "#{message.user.nick}: #{Settings.get["messages"]["thanks"]}"
              rescue CommandNotFoundException
                message.reply "#{message.user.nick}: #{Settings.get["messages"]["command_not_found"]}"
              rescue MessageAlreadyAddedException
                message.reply "#{message.user.nick}: #{Settings.get["messages"]["message_already_added"]}"
              end
            elsif message_parts[2] == "add"
              begin
                database.add_message(message_parts[0..1], message_parts[3..-1].join(" "))
                message.reply "#{message.user.nick}: #{Settings.get["messages"]["thanks"]}"
              rescue CommandNotFoundException
                message.reply "#{message.user.nick}: #{Settings.get["messages"]["command_not_found"]}"
              rescue MessageAlreadyAddedException
                message.reply "#{message.user.nick}: #{Settings.get["messages"]["message_already_added"]}"
              end
            else
              target = text.split.last

              if text == target
                target = message.user.nick
              end

              begin
                random_message = database.random_message(text)
                if random_message
                  message.reply "#{target}: #{random_message}"
                else
                  message.reply "#{message.user.nick}: #{Settings.get["messages"]["no_messages"]}"
                end
              rescue CommandNotFoundException
                message.reply "#{message.user.nick}: #{Settings.get["messages"]["command_not_found"]}"
              end
            end
          end
        end
      end
    end
  end
end

bot.start

