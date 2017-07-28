require 'line/bot'
require 'json'
require 'roo'
require 'open-uri'
class WebhookController < ApplicationController
  protect_from_forgery with: :null_session # CSRF対策無効化
 

  def get_sample
    file = File.read("db/test.json")
    data_hash = JSON.parse(file)
    #binding.pry
    #result=deep_find_value_with_key(data_hash,"1")
    # binding.pry
    #build_template_message(data_hash,"1","123")
   
    #render :text => deep_find_value_with_key(data_hash,"3")
    #binding.pry
    #messages
    
    #build_template execute_near_movietheather("222")
    #render :json => deep_find_value_with_key(data_hash,"3")
    render :text =>  execute("",data_hash)
  end 

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    file = File.read("db/test.json")
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
          message = execute_near_movietheather(event)
          client.reply_message(event['replyToken'], message)
        end
      end 
    }
    render status: 200, json: { message: 'OK' }
  end

  private
  def execute(event,movie)
    text = event.message['text']
    #text ="映画を探す"
    if text.include?("映画を探す")
      result = deep_find_value_with_key(movie,"1")
      @current_id = result["id"]
      if result["next_type"] == "message" && result["children"].length >= 2
        @confirm_actions = []
        result["children"].each do |a|
          #action
          @label = a["label"]
          @text = a["label"]  
          @confirm_actions.push(confirm_actions[0])
        end
          #template
          @altText = result["label"]
          @current_id = result["id"]
          @type = template_type.find {|item| item == "confirm" }
          #Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: result["id"], next_qid: "")
          reply_template
      end
    end
   # else
      #result = deep_find_value_with_key(movie,@current_id)
       
    # if text == "はじめまして" then
    #   Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["qid"], next_qid: question["choice"][0]["ch_id"])
    #   #reply_text(movie["context_name"].concat("です"))
    # elsif text.include?("映画") then 
    #   Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["question"]["qid"], next_qid: movie["question"]["choice"][0]["ch_id"])
    #   deep_find_value_with_key(movie,1)
    #   reply_template(movie["question"])
    # elsif text.include?("はい") then    
    #   Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["question"]["choice"][0]["ch_id"], next_qid: "0")
    #   reply_text(movie["question"]["choice"][0]["finish"]["content"])
    # elsif text.include?("いいえ") then 
    #   Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: movie["question"]["choice"][1]["ch_id"], next_qid: movie["question"]["choice"][1]["question"]["ch_id"])
    #   replay_button(movie["question"]["choice"][1]["question"])
    # elsif reply_text_from_json(movie["question"]["choice"][1]["question"],text)!=nil then
    #   Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: reply_qid_from_json(movie["question"]["choice"][1]["question"],text), next_qid: "0")
    #   reply_text(reply_text_from_json(movie["question"]["choice"][1]["question"],text)["content"])
    # else
    #   reply_text("メッセージありがとうございます")
    #   #Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: "0", next_qid: "0")
    # end
 
  end

  def execute_near_movietheather(event)
    build_template(event['message']['latitude'].to_s,event['message']['longitude'].to_s)
  end
  
  
  def deep_find_value_with_key(data, desired_key)
    case data
      when Array
        data.each do |value|
        if found = deep_find_value_with_key(value, desired_key)
          return found
        end
      end
      when Hash
        if data["id"].to_s == desired_key
          return data
        else
          data.each do |key, val|
            if found = deep_find_value_with_key(val, desired_key)
              return found
            end
          end
        end
      end
    return nil
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
  
  def build_template_message(movie,id,message)
    if message == "映画"
       result=deep_find_value_with_key(movie,id)
       @current_id = result["id"]
    else
      result=deep_find_value_with_key(movie,id)
      if result["next_type"]== "message" && result["children"].length >= 2
        @confirm_actions = []
        result["children"].each do |a|
          #action
          @label = a["label"]
          @text = a["label"]  
          @confirm_actions.push(confirm_actions[0])
        end
          #template
          @altText = result["label"]
          @type = template_type.find {|item| item == "confirm" }
          @current_id = result["id"]
          reply_template
        
        elsif result["next_type"] == "question" && result["children"].length >= 2
          #reply_template_2
        else
          if result["children"].length>2
          end
        end
        

    end
    
  end
  # def reply_template(question)
  #   [
  #     {
  #       type: "template",
  #       altText: question["label"],
  #       template: 
  #       {
  #         type: "confirm",
  #         text: question["body"]["content"],
  #         actions: 
  #         [
  #           {
  #             type: "message",
  #             label: question["choice"][0]["label"],
  #             text: question["choice"][0]["label"]
  #           },
  #           {
  #             type: "message",
  #             label: question["choice"][1]["label"],
  #             text: question["choice"][1]["label"]
  #           }
  #         ]
  #       }
  #     }
  #   ]
  # end

  def reply_template
    [
      {
        type: "template",
        altText: @altText,
        template: 
        {
          type: @type,
          text: @altText,
          actions: @confirm_actions       
        }
      }
    ]
  end
  def confirm_actions
    [
      {
        type: "message",
        label: @label,
        text: @text
      }
    ]
  end

  # def reply_carousel(question)
  #   [
  #     {
  #       type: "template",
  #       altText: "this is a carousel template",
  #       template: 
  #       {
  #         type: "carousel",
  #         columns: 
  #         [
  #           {
  #             thumbnailImageUrl: "https://example.com/bot/images/item1.jpg",
  #             title: "this is menu",
  #             text: "description",
  #             actions: 
  #             [
  #               {
  #                 type: "postback",
  #                 label: "Buy",
  #                 data: "action=buy&itemid=111"
  #               },
  #               {
  #                 type: "postback",
  #                 label: "Add to cart",
  #                 data: "action=add&itemid=111"
  #               },
  #               {
  #                 type: "uri",
  #                 label: "View detail",
  #                 uri: "http://example.com/page/111"
  #               }
  #             ]
  #           },
  #           {
  #             thumbnailImageUrl: "https://example.com/bot/images/item2.jpg",
  #             title: "this is menu",
  #             text: "description",
  #             actions: 
  #             [
  #               {
  #                 type: "postback",
  #                 label: "Buy",
  #                 data: "action=buy&itemid=222"
  #               },
  #               {
  #                 type: "postback",
  #                 label: "Add to cart",
  #                 data: "action=add&itemid=222"
  #               },
  #               {
  #                 type: "uri",
  #                 label: "View detail",
  #                 uri: "http://example.com/page/222"
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     }
  #   ]
  # end
  
  # def replay_button(question)
  #   [
  #     {
  #       type: "template",
  #       altText: question["label"],
  #       template: 
  #       {
  #         type: "buttons",
  #         thumbnailImageUrl: "https://example.com/bot/images/image.jpg",
  #         title: question["body"]["content"],
  #         text: question["body"]["content"],
  #         actions:
  #         [
  #           {
  #             type: "message",
  #             label: question["choice"][0]["label"],
  #             text: question["choice"][0]["label"]
  #           },
  #           {
  #             type: "message",
  #             label: question["choice"][1]["label"],
  #             text: question["choice"][1]["label"]
  #           },
  #           {
  #             type: "message",
  #             label: question["choice"][2]["label"],
  #             text: question["choice"][2]["label"]
  #           }
  #         ]
  #       }
  #     }
  #   ]
  # end

  def actions
    [
      {
        type: 'uri',
        label: 'この映画館を検索',
        uri: @googleSearchUrl
      },
      {
        type: 'uri',
        label: 'ここからのルート',
        uri: @googleMapRouteUrl
      }
    ]
  end

  def columns
    [
      {
        title: @title,
        text: 'ここから'+@distance.to_s+'km - '+ @address,
        actions: actions
      }
    ]
  end

  def messages
    [
      {
        type: 'template',
        altText: 'なにか',
        template: {
          type: 'carousel',
          columns: @columns
        }
      }
    ]
  end

  def get_near_movietheather(latitude, longitude)
    yahoo_url = "https://map.yahooapis.jp/search/local/V1/localSearch"
    params = {
      'appid' => 'dj00aiZpPUVTUEpFMHVZNng4UyZzPWNvbnN1bWVyc2VjcmV0Jng9YjA-',
      'dist' => '5',
      'gc' => '0305001',
      'results' => '5',
      'lat' => latitude,
      'lon' => longitude,
      'output' => 'json',
      'sort' => 'dist'
    }
    url = yahoo_url + '?' + URI.encode_www_form(params)
    json = open(url).read
    data = JSON.parse(json)['Feature']

    movie_theaters = []
    
    data.each do |item|
      map = {}
      map["uid"] = item['Property']['Uid']
      map["name"] = item['Name']
      map["address"] = item['Property']['Address']
      map["coords"] = item['Geometry']['Coordinates'].split(',')
      map["map_longitude"] = map["coords"][0]
      map["map_latitude"] = map["coords"][1]
      map["distance"] = get_distanceInKilloMeters(latitude,longitude,map["map_latitude"],map["map_longitude"])
      map["google_search"] = get_google_search_url(map["name"])
      map["how_to_go"] = get_google_map_route_url(latitude,longitude,map["map_latitude"],map["map_longitude"])
      movie_theaters.push(map)
    end
    movie_theaters
  end

  def get_distanceInKilloMeters(latitude1, longitude1, latitude2, longitude2) 
    yahoo_dis_url = 'https://map.yahooapis.jp/dist/V1/distance'
    params = {
      'coordinates' => longitude1 + ',' + latitude1 +  URI.encode_www_form_component(' ') + longitude2 + ',' + latitude2,
      'appid' => 'dj00aiZpPUVTUEpFMHVZNng4UyZzPWNvbnN1bWVyc2VjcmV0Jng9YjA-',
      'output' => 'json'
    }
    url = yahoo_dis_url + '?' + URI.encode_www_form(params)
     
    json = open(url).read
    distance = JSON.parse(json)['Feature'][0]['Geometry']['Distance']
    distance = distance * 10
    result = distance.round(distance.to_f * 10) /10
  end

  def get_google_search_url(query)
    'https://www.google.co.jp/search?q=' + URI.encode_www_form_component(query) + '&ie=UTF-8'
  end

  def get_google_map_route_url(srcLatitude, srcLongitude, destLatitude, destLongitude) 
    'http://maps.google.com/maps' + '?saddr=' +srcLatitude + ',' + srcLongitude + '&daddr=' + destLatitude + ',' + destLongitude+ '&dirflg=w';
  end

  def build_template(latitude, longitude)
    data = get_near_movietheather(latitude, longitude)
    @column = []
    data.each do | item |  
      @title = item["name"]
      @distance = item["distance"]
      @address = item["address"]
      @googleSearchUrl = item["google_search"]
      @googleMapRouteUrl = item["how_to_go"]
      @column.push(columns[0])
    end
    messages   
  end

  def template_type
    ["carousel","confirm","buttons"]
  end
end





