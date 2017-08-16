require "redis"
require "tiny"
require "./likes/*"

module Likes
  redis = Redis.new

  serve do |request, response|
    response.allow_header "Origin"
    response.allow_header "Access-Control-Request-Method"
    response.allow_header "Access-Control-Request-Header"
    response.allow_header "Content-Type"

    request.get do
      # If no URL is provided, return a status message
      unless request.params.has_key? "url"
        next response.json({
          "message" => "The server is up and running",
          "timestamp" => Time.now.to_s
        })
      end

      # Return the count for the provided URL
      url = request.params["url"]
      if count = redis.get("posts.likes.#{url}")
        count = count.to_i64
      else
        count = 0_i64
      end

      next response.json({
        "likes" => count
      })
    end

    request.post do
      # If no URL is provided, return an error
      unless request.params.has_key? "url"
        next response.error "You must provide a URL"
      end

      # Increment the count for the provided URL
      url = request.params["url"]

      # Increment or decrement the count as requested
      if count = redis.get("posts.likes.#{url}")
        if request.params.has_key?("unlike") && request.params["unlike"] == true
          redis.decr "posts.likes.#{url}"
        else
          redis.incr "posts.likes.#{url}"
        end
      else
        unless request.params.has_key?("unlike") && request.params["unlike"] == true
          redis.set("posts.likes.#{url}", 1_i64)
        end
      end

      next response.json({
        "success" => true
      })
    end
  end
end
