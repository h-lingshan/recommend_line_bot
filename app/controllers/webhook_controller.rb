require 'line/bot'
require 'net/http'
require 'json'
require 'roo'
class WebhookController < ApplicationController
  protect_from_forgery with: :null_session # CSRF対策無効化

  def get_sample
   #file = File.read("db/sample.json")
    #data_hash = JSON.parse(file)
   
    #render :text => reply_text_from_json(data_hash["question"]["choice"][1]["question"],"123")!= nil 
    #render :text => get_near_movietheather("35.660493", "139.775282")
    doc = Roo::Spreadsheet.open("db/chatbot.xlsx")
    #xlsx.sheet('Sheet1').row(1)
   # xlsx.sheet('Sheet1').column(1)
   # xlsx.first_row(sheet.sheets[0])
    # => 1             # the number of the first row
    #xlsx.last_row
    # => 42            # the number of the last row
    #xlsx.first_column
    # => 1             # the number of the first column
    #xlsx.last_column
    # => 10            # the number of the last column
    headers = {}
   (doc.sheet("Sheet1").first_column..doc.sheet("Sheet1").last_column).each do |col|
     headers[col] = doc.cell(doc.first_row, col)
   end
   #binding.pry
   hash = {}
   hash[:data] = []
   ((doc.first_row + 1)..doc.last_row).each do |row|
     row_data = {}
       headers.keys.each do |col|
         value = doc.cell(row, col)
         
    # rooは整数値もfloatとして返すので，整数値なら整数に変換する（必要なければコメントアウトして良い）
         #value = value.to_i if doc.celltype(row, col) == :float && value.modulo(1) == 0.0
         row_data[headers[col]] = value
       end
     hash[:data] << row_data
   end
    event =[
    {
      "events"=>[{
        "type"=>"message", "replyToken"=>"f4ad1254b8b7448e82bb0d84de1a31bb", 
        "source"=>{"userId"=>"Ubcd2b753b73e467880b4ab3f47f35d13", "type"=>"user"}, 
        "timestamp"=>1500361375769, 
        "message"=>{"type"=>"text", "id"=>"6405222023772", "text"=>"映画を探す"}}], 
        "webhook"=>{
          "events"=>[{
            "type"=>"message", "replyToken"=>"f4ad1254b8b7448e82bb0d84de1a31bb", 
            "source"=>{"userId"=>"Ubcd2b753b73e467880b4ab3f47f35d13", "type"=>"user"}, 
            "timestamp"=>1500361375769, 
            "message"=>{"type"=>"text", "id"=>"6405222023772", "text"=>"映画を探す"}}
            ]
        }
    }
    ]

#puts hash.to_json
     Log.create(user_name: "123", type: "123", content: "22222", current_qid: "1-2", next_qid: "123")
    render :text =>event

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
    Log.create(user_name: "1", type: "0", content: "0", current_qid: "0", next_qid: "0")
    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = execute(event,data_hash)    
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Location
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
      Log.create(user_name: "0", type: "0", content: "0", current_qid: "0", next_qid: "0")
      reply_text(movie["context_name"].concat("です"))
      #Log.create(user_name: "0", type: "0", content: text, current_qid: "0", next_qid: "0")
    elsif text.include?("映画") then
      reply_template(movie["question"])
      L#og.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["qid"], next_qid: question["choice"][0]["ch_id"])
    elsif text.include?("はい") then
      reply_text(movie["question"]["choice"][0]["finish"]["content"])
     # Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["chi_id"], next_qid: "0")
    elsif text.include?("いいえ") then
      replay_button(movie["question"]["choice"][1]["question"])
      #Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["chi_id"], next_qid: "0")
    elsif reply_text_from_json(movie["question"]["choice"][1]["question"],text)!=nil then
      reply_text(reply_text_from_json(movie["question"]["choice"][1]["question"],text)["content"])
      #Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: reply_qid_from_json(movie["question"]["choice"][1]["question"],text), next_qid: "0")
    else
      reply_text("メッセージありがとうございます")
      #Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: "0", next_qid: "0")
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
  def reply_qid_from_json(question,msg)
    question["choice"].map{|h| h['ch_id'] if h['label']==msg}.compact.first
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

  def get_near_movietheather(latitude, longitude)
     yahoo_uri = "https://map.yahooapis.jp/search/local/V1/localSearch"
     params = Hash.new
     params.store("appid","dj00aiZpPUVTUEpFMHVZNng4UyZzPWNvbnN1bWVyc2VjcmV0Jng9YjA-")
     params.store("dist",3)
     params.store("gc",0424002)
     params.store("results",5)
     params.store("lat",latitude)
     params.store("lon",longitude)
     params.store("output","json")
     params.store("sort","dist")
     #text = "https://map.yahooapis.jp/search/local/V1/localSearch" + "?appid=" + "dj00aiZpPUVTUEpFMHVZNng4UyZzPWNvbnN1bWVyc2VjcmV0Jng9YjA-" + "&dist=3" + "&gc=0424002" + "&results=5"  + "&lat=" + latitude  + "&lon=" + longitude + "&output=json&sort=dist"
     req = Net::HTTP::Post.new uri.path
     req.set_form_data(params)
     res = Net::HTTP.start(uri.host, uri.port) {|http| http.request req }
     binding.pry
     return res
  
  end
end