require "net/http"
require "json"
require "thread"

module Pr0gram
  @@comments = {}
  @@comments_lock = Mutex.new

  def self.refresh
    @@comments_lock.synchronize {
      data = JSON.parse(Net::HTTP.get(URI("http://pr0gramm.com/api/items/get")))

      data["items"].each do |item|
        user = item["user"]
        if !@@comments[user]
          user_data = JSON.parse(Net::HTTP.get(URI("http://pr0gramm.com/api/profile/info?name=#{user}")))
          @@comments[user] = user_data["comments"]
          break
        end
      end
    }
  end
  
  def self.random_comment
    comment = nil

    @@comments_lock.synchronize {
      random_index = Random.rand(@@comments.length)
      @@comments.each_with_index { |(key,value),index|
        if index == random_index
          comment = { user: key, comment: value }
        end
      }
    }

    comment
  end
end
