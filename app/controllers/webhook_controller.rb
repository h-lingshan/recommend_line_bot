require 'line/bot'
require 'json'
class WebhookController < ApplicationController
  protect_from_forgery with: :null_session # CSRF対策無効化

  def get_sample
   file = File.read("db/sample.json")
    data_hash = JSON.parse(file)
    @data_hash = data_hash
    render :text =>  data_hash
  end 

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    file = File.read("db/sample.json")
    data_hash = JSON.parse(file)

    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    # this statement maybe mistake.
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
           type: "template",
           altText: data_hash["question"]["label"],
           template: {
             type: "confirm",
             text: data_hash["question"]["body"]["content"],
             actions: [
               {
                 type: "message",
                 label: data_hash["question"]["choice"][0]["label"],
                 text: data_hash["question"]["choice"][0]["label"]
               },
               {
                 type: "message",
                 label: data_hash["question"]["choice"][1]["label"],
                 text: data_hash["question"]["choice"][1]["label"]
               }
             ]
           }
          }        
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
    end
  }
    render status: 200, json: { message: 'OK' }
  end

  def receive_follow(message_target)
    client.push_message(
      message_target.platform_id, # userIdが入る
      {
        type: "text",
        text: "友達登録ありがとうございます！"
      }
    )
  end

end