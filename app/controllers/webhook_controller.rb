class WebhookController < ApplicationController
  require 'line/bot'
  protect_from_forgery :except => [:callback]

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
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
            type: 'text',
            text: event.message['text']
          }
          response = client.reply_message(event['replyToken'], message)
          #p response
        end
      end
    }
    head :ok, content_type: "text/html"
  end

  private
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = '46df53f193dda8eb08d53576a339539d'
      config.channel_token = 'pcHXd6+4UHO40EE/vXQgnDXROkCNiY/BcgErWoYGWuFlLw6I4zotW0rT/qxV9J3W3Nfb+e+Co1g7tfxFrCnyIiKASQt6lkgjft2Zp+rv/lvfhU5Iju0WjvihjDK2si2Wo0uERAU9771h149J7oGrdwdB04t89/1O/w1cDnyilFU='
    }
  end
end