require 'line/bot'
<<<<<<< HEAD
require 'json'
=======

>>>>>>> 5348b313aa7b5b7e7e66f5fbe60977133370fbe9
class WebhookController < ApplicationController
  protect_from_forgery with: :null_session # CSRF対策無効化

  def client
<<<<<<< HEAD
      #間違えればresponseは400に入る
=======
>>>>>>> 5348b313aa7b5b7e7e66f5fbe60977133370fbe9
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
<<<<<<< HEAD
　
　
  def callback
    # ユーザーからのリクエスト
    body = request.body.read
　　　#　検証
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    # this statement maybe mistake.
　　 #　ユーザーのリクエストは署名検証というheaderを付けされる
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
　　# ユーザーへの返信
=======

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    # this statement maybe mistake.
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

>>>>>>> 5348b313aa7b5b7e7e66f5fbe60977133370fbe9
    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
<<<<<<< HEAD
=======
        when Line::Bot::Event::Follow
        receive_follow(message_target)
>>>>>>> 5348b313aa7b5b7e7e66f5fbe60977133370fbe9
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']
          }
          response = client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
<<<<<<< HEAD
=======
        
>>>>>>> 5348b313aa7b5b7e7e66f5fbe60977133370fbe9
      end
    }

    render status: 200, json: { message: 'OK' }
<<<<<<< HEAD
=======
  end

  def receive_follow(message_target)
    client.push_message(
      message_target.platform_id, # userIdが入る
      {
        type: "text",
        text: "友達登録ありがとうございます！"
      }
    )
>>>>>>> 5348b313aa7b5b7e7e66f5fbe60977133370fbe9
  end

end