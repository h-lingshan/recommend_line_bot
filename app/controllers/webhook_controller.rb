require 'line/bot'
require 'json'
class WebhookController < ApplicationController
  protect_from_forgery with: :null_session # CSRF対策無効化

  def get_sample
   file = File.read("db/sample.json")
    data_hash = JSON.parse(file)
   
    render :text => reply_text_from_json(data_hash["question"]["choice"][1]["question"],"君の名は")["content"]
    
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
          message = execute(event,data_hash)    
          client.reply_message(event['replyToken'], message)
        end
      end 
    }
    render status: 200, json: { message: 'OK' }
  end

  private
  def execute(event,movie)
    text = event.message['text']

    if text == "はじめまして" then
      reply_text(movie["context_name"].concat("です"))
    elsif text.include?("映画") then
      reply_template(movie["question"])
    elsif text.include?("はい") then
      reply_text(movie["question"]["choice"][0]["finish"]["content"])
    elsif text.include?("いいえ") then
      replay_button(movie["question"]["choice"][1]["question"])
    elsif reply_text_from_json(movie["question"]["choice"][1]["question"],text).compact
      reply_text(reply_text_from_json(movie["question"]["choice"][1]["question"],text)["content"])
    else
      reply_text("メッセージありがとうございます")
    end
 
  end

  def reply_text(msg)
    [
      {
      type: "text",
      text: msg
      }
    ]
  end
  def reply_text_from_json(question,msg)
    question["choice"].map{|h| h['finish'] if h['label']==msg}.compact.first
  end
  def reply_template(question)
    [
      {
        type: "template",
        altText: question["label"],
        template: 
        {
          type: "confirm",
          text: question["body"]["content"],
          actions: 
          [
            {
              type: "message",
              label: question["choice"][0]["label"],
              text: question["choice"][0]["label"]
            },
            {
              type: "message",
              label: question["choice"][1]["label"],
              text: question["choice"][1]["label"]
            }
          ]
        }
      }
    ]
  end

  def reply_carousel(question)
    [
      {
        type: "template",
        altText: "this is a carousel template",
        template: 
        {
          type: "carousel",
          columns: 
          [
            {
              thumbnailImageUrl: "https://example.com/bot/images/item1.jpg",
              title: "this is menu",
              text: "description",
              actions: 
              [
                {
                  type: "postback",
                  label: "Buy",
                  data: "action=buy&itemid=111"
                },
                {
                  type: "postback",
                  label: "Add to cart",
                  data: "action=add&itemid=111"
                },
                {
                  type: "uri",
                  label: "View detail",
                  uri: "http://example.com/page/111"
                }
              ]
            },
            {
              thumbnailImageUrl: "https://example.com/bot/images/item2.jpg",
              title: "this is menu",
              text: "description",
              actions: 
              [
                {
                  type: "postback",
                  label: "Buy",
                  data: "action=buy&itemid=222"
                },
                {
                  type: "postback",
                  label: "Add to cart",
                  data: "action=add&itemid=222"
                },
                {
                  type: "uri",
                  label: "View detail",
                  uri: "http://example.com/page/222"
                }
              ]
            }
          ]
        }
      }
    ]
  end

  def replay_button(question)
    [
      {
        type: "template",
        altText: question["label"],
        template: 
        {
          type: "buttons",
          thumbnailImageUrl: "https://example.com/bot/images/image.jpg",
          title: question["body"]["content"],
          text: question["body"]["content"],
          actions:
          [
            {
              type: "message",
              label: question["choice"][0]["label"],
              text: question["choice"][0]["label"]
            },
            {
              type: "message",
              label: question["choice"][1]["label"],
              text: question["choice"][1]["label"]
            },
            {
              type: "message",
              label: question["choice"][2]["label"],
              text: question["choice"][2]["label"]
            }
          ]
        }
      }
    ]
  end

  def test(text,question)
    text = text

    if text == "はじめまして" then
      msg = "Line Botです"
    elsif question["context_name"].include?(text) then
      msg = question["context_name"]
    else
      msg = "メッセージありがとうございます"
    end
    [
      {
      type: "text",
      text: msg
      }
    ]
  end
end