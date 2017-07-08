class WebhookController < ApplicationController
  
  protect_from_forgery :except => [:callback]

require 'line/bot'
require 'net/http'

def client
       client = Line::Bot::Client.new { |config|
 config.channel_secret = '46df53f193dda8eb08d53576a339539d'
 config.channel_token = 'pcHXd6+4UHO40EE/vXQgnDXROkCNiY/BcgErWoYGWuFlLw6I4zotW0rT/qxV9J3W3Nfb+e+Co1g7tfxFrCnyIiKASQt6lkgjft2Zp+rv/lvfhU5Iju0WjvihjDK2si2Wo0uERAU9771h149J7oGrdwdB04t89/1O/w1cDnyilFU='
 }
end



def callback

  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']

  event = params["events"][0]
  event_type = event["type"]

  #送られたテキストメッセージをinput_textに取得
  input_text = event["message"]["text"]

  events = client.parse_events_from(body)

  events.each { |event|

    case event
      when Line::Bot::Event::Message
        case event.type
          #テキストメッセージが送られた場合、そのままおうむ返しする
          when Line::Bot::Event::MessageType::Text
             message = {
                  type: 'text',
                  text: input_text
                  }
         end #event.type
         #メッセージを返す
         client.reply_message(event['replyToken'],message)
    end #event
 } #events.each
 render :nothing => true, status: :ok
end  #def


end