 #require 'line/bot'
 
 class WebhookController < ApplicationController
  protect_from_forgery with: :null_session


#   def callback
#     body = request.body.read

#     signature = request.env['HTTP_X_LINE_SIGNATURE']
#     unless client.validate_signature(body, signature)
#       error 400 do 'Bad Request' end
#     end

#     events = client.parse_events_from(body)
#     events.each { |event|
#       case event
#       when Line::Bot::Event::Message
#         case event.type
#         when Line::Bot::Event::MessageType::Text
#           message = {
#             type: 'text',
#             text: event.message['text']
#           }
#           response = client.reply_message(event['replyToken'], message)
#           p response
#         end
#       end
#     }
#     render status: 200, json: { message: 'OK' }
#   end

#   private
#   def client
#     @client ||= Line::Bot::Client.new { |config|
#       config.channel_secret = ENV["CHANNEL_SECRET"]
#       config.channel_token = ENV["CHANNEL_ACCESS_TOKEN"]
#     }
#   end

CHANNEL_SECRET = ENV['CHANNEL_SECRET']
  OUTBOUND_PROXY = ENV['OUTBOUND_PROXY']
  CHANNEL_ACCESS_TOKEN = ENV['CHANNEL_ACCESS_TOKEN']

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end

    event = params["events"][0]
    event_type = event["type"]
    replyToken = event["replyToken"]

    case event_type
    when "message"
      input_text = event["message"]["text"]
      output_text = input_text
    end

    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, output_text)

    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end

    render :nothing => true, status: :ok
  end
  private
  # verify access from LINE
  def is_validate_signature
    signature = request.headers["X-LINE-Signature"]
    http_request_body = request.raw_post
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, CHANNEL_SECRET, http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end
end

