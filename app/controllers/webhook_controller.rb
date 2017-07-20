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
    movies = []
    doc.sheet("Sheet3").each(id: 'id', label: 'label', next_type: 'next_type', parent_id: 'parent_id', to_web: 'to_web') do |hash|   
      movies.push(hash)
    end

    #親idだけ
    parent_ids = []
    parent_ids.push(movies.map{ |movie| movie[:parent_id]}.drop(1))
    
    #カテゴリーの最下層のidを配列に保持
    term_bottom = []
    movies.drop(1).each do | movie |
      if !parent_ids.to_s.include?(movie[:id].to_s)
        term_bottom.push(movie[:id])
      end
    end

    #最下層の配列をループして木構造の頂点まで
    category = []
    term_bottom.each do | id |
      category.push(set_ids(id, movies))
    end
   
    # category.each do | ids |
    #   ids.each do | id |

    #     movie = movies.select{|movie| movie[:id]== id}[0]
        
    #     if movie[:parent_id].to_i == 0
    #       json << "id" << ":" << movie[:id].to_s
    #       json << ","
    #       json << "label" << ":" << movie[:label].to_s
    #       json << ","
    #       json << "next_type" << ":" << movie[:next_type].to_s
    #     else
          
    #     end
    #   end
    # end

   
    binding.pry
    root = movies.second
    map = {}

    movies.drop(2).each do |e|
      map[e[:id]] = e
    end

    @@tree = {}

      movies.drop(2).each do |e|
        pid = e[:parent_id]
        if pid == nil || !map.has_key?(pid)
          (@@tree[root] ||= []) << e
        else
          (@@tree[map[pid]] ||= []) << e
        end
      end
    binding.pry
    render :text => json

  end 

  def print_tree(item, level)
  items = @@tree[item]
  unless items == nil
    indent = level > 0 ? sprintf("%#{level * 2}s", " ") : ""
    items.each do |e|
      puts "#{indent}-#{e[:title]}"
      print_tree(e, level + 1)
    end
  end
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
      Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["qid"], next_qid: question["choice"][0]["ch_id"])
      #reply_text(movie["context_name"].concat("です"))
    elsif text.include?("映画") then 
      Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["question"]["qid"], next_qid: movie["question"]["choice"][0]["ch_id"])
      reply_template(movie["question"])
    elsif text.include?("はい") then    
      Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["question"]["choice"][0]["ch_id"], next_qid: "0")
      reply_text(movie["question"]["choice"][0]["finish"]["content"])
    elsif text.include?("いいえ") then 
      Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["question"]["choice"][1]["ch_id"], next_qid: movie["question"]["choice"][1]["question"]["ch_id"])
      replay_button(movie["question"]["choice"][1]["question"])
    elsif reply_text_from_json(movie["question"]["choice"][1]["question"],text)!=nil then
      Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: reply_qid_from_json(movie["question"]["choice"][1]["question"],text), next_qid: "0")
      reply_text(reply_text_from_json(movie["question"]["choice"][1]["question"],text)["content"])
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
    
     return res
  
  end

  def set_ids(id, movies, args = [])
    if id == 0
      return args.reverse
    else
      args.push(id)
      movies.each do | movie |
        if movie[:id] == id
          return set_ids(movie[:parent_id], movies, args)
        end
      end
    end
  end
end
