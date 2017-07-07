 class WebhookController < ApplicationController
  protect_from_forgery :except => [:callback]
 require 'line/bot'
 require 'net/http'
  

 def client
  client = Line::Bot::Client.new { |config|
  config.channel_secret = ENV["CHANNEL_SECRET"]
  config.channel_token = ENV["CHANNEL_ACCESS_TOKEN"]
  }
 end

 def callback
  body = request.body.read
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  event = params["events"][0]
  event_type = event["type"]
  input_text = event["message"]["text"]
  events = client.parse_events_from(body)
  events.each { |event|
   case event
    when Line::Bot::Event::Message
     case event.type
      when Line::Bot::Event::MessageType::Text
       if input_text.include?("スティーブン") || input_text.include?('Stephen')
        message = {
          type: 'text',
          text: '僕、「エルロボ」のデザイナー、スティーブン・マーフィーのことかな？'
          }
       elsif input_text == 'id'
        message = {
          type: 'text',
          text: "あなたのuseridは\n" + user_id + "\nです。"
          }
       else
        message = {
          type: 'text',
          text: input_text
          }
       end

      when Line::Bot::Event::MessageType::Image
       image_url = "https://el-robo.com/elrobo1.png" #httpsであること
        message = {
          type: "image",
          originalContentUrl: image_url,
          previewImageUrl: image_url
          }
      end #event.type
      #メッセージを返す
      client.reply_message(event['replyToken'],message)
   end
  }

 end

  end