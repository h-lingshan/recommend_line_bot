require 'line/bot'
require 'timeout'
class WebhookController < ApplicationController
  protect_from_forgery with: :null_session # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
   
    begin
      Timeout.timeout(5) do
        message = {
          type: 'text',
          text: 'こんにちは、映画サジェストです。'
        }
        response = client.push_message("<to>",message)
        p response
      end
    end

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
          msg = event.message['text']
          message = {
            type: 'text',
            text: event.message['text']
          }
          response = client.reply_message(event['replyToken'], message)
      end
    }

    render status: 200, json: { message: 'OK' }
  end
end