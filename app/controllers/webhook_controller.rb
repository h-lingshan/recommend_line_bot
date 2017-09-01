require 'line/bot'
require 'json'
require 'roo'
require 'open-uri'
class WebhookController < ApplicationController
  protect_from_forgery with: :null_session # CSRF対策無効化
 

  def get_sample
   
    file = File.read("db/converted_file.json")
    data_hash = JSON.parse(file) 
    #result=deep_find_value_with_key(data_hash,"1")
    #build_template_message(data_hash,"1","123")
    #render :json => data_hash
    #temp = {"events"=>[{"type"=>"postback", "replyToken"=>"e84d6e6c8b7e4abfadda336d4d5f57de", "source"=>{"userId"=>"Ubcd2b753b73e467880b4ab3f47f35d13", "type"=>"user"}, "timestamp"=>1501232128077, "postback"=>{"data"=>"id=3&parent_id=1"}}], "webhook"=>{"events"=>[{"type"=>"postback", "replyToken"=>"e84d6e6c8b7e4abfadda336d4d5f57de", "source"=>{"userId"=>"Ubcd2b753b73e467880b4ab3f47f35d13", "type"=>"user"}, "timestamp"=>1501232128077, "postback"=>{"data"=>"id=3&parent_id=1"}}]}}
    #temp_a = JSON.parse(temp.to_json)  
    render :text =>  execute_post_back("",data_hash)
  end 

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    file = File.read("db/converted_file.json")
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
      when Line::Bot::Event::Postback
          message = execute_post_back(event,data_hash)    
          client.reply_message(event['replyToken'], message)
      end 
    }
    render status: 200, json: { message: 'OK' }
  end

  private
  def execute(event,movie)
    text = event.message['text'] 
    Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: text, current_qid: "", next_qid: "")
    send_google_analytics(text)
    
    if text.include?("映画を探す")  
      movie.extend(Hashie::Extensions::DeepLocate)
      movie = movie.deep_locate -> (key, value, object) { key == "id" && value == 1 }
      result = movie
      if result[0].key?("children")
        @confirm_actions = []
        result[0]["children"].each do |a|
          #action
          @label = a["label"]
          @text = a["label"]  
          @post_id = "id="+ a["id"].to_s+ "&"+ "parent_id="+ a["parent_id"].to_s
          @confirm_actions.push(confirm_actions[0])
        end
          #template
          @altText = result[0]["label"]
          @type = template_type.find {|item| item == "confirm" }
          reply_template
      end
    else  
      reply_text("メッセージありがとうございます")
    end  
  end

  def execute_post_back(event,movie)
    id = event["postback"]["data"].split("&")[0].split("=")[1].to_i
    parent_id = event["postback"]["data"].split("&")[1].split("=")[1].to_s
    Log.create(user_name: event['source']['userId'], type: event['source']['type'], content: id, current_qid: id, next_qid: parent_id) 
    send_google_analytics(id)
    result = deep_find_value_with_key(movie,id,parent_id)
      if result[0].key?("children")
        @confirm_actions = []
        result[0]["children"].each do |item|
          @altText = item["label"]
          @type = template_type.find {|item| item == "buttons" }
          if item.key?("children")
            result = deep_find_value_with_key(movie,item["id"], item["parent_id"].to_s)
            
            @altText = result[0]["label"]
            @confirm_actions = []
            result[0]["children"].each do |a|
              @label = a["label"]
              @text = a["label"]
              @post_id = "id="+ a["id"].to_s+ "&"+ "parent_id="+ a["parent_id"].to_s
              @confirm_actions.push(confirm_actions[0])
            end   
            return reply_template
          else
            @label = item["label"]
            @text = item["label"]
            @post_id = "id="+ item["id"].to_s+ "&"+ "parent_id="+ item["parent_id"].to_s
            @confirm_actions.push(confirm_actions[0])
          end 
        end 
        return reply_template
      else
        return reply_text(result[0]["label"]+ "," + result[0]["to_web"])
      end
  end

  def execute_near_movietheather(event)
    build_template(event['message']['latitude'].to_s,event['message']['longitude'].to_s)
  end
  
  def deep_find_value_with_key(movie,id,parent_id)
    movie.extend(Hashie::Extensions::DeepLocate)
    movie = movie.deep_locate -> (key, value, object) { key == "id" && value == id }
    movie.extend(Hashie::Extensions::DeepLocate)
    movie = movie.deep_locate -> (key, value, object) { key == "parent_id" && value == parent_id }
    movie
  end

  def reply_text(msg)
    [
      {
      type: "text",
      text: msg
      }
    ]
  end

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
        type: "postback",
        data: @post_id,
        label: @label
      }
    ]
  end

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
    @columns = []
    data.each do | item |  
      @title = item["name"]
      @distance = item["distance"]
      @address = item["address"]
      @googleSearchUrl = item["google_search"]
      @googleMapRouteUrl = item["how_to_go"]
      @columns.push(columns[0])
    end
    messages   
  end

  def template_type
    ["carousel","confirm","buttons"]
  end

  def next_type
    ["question", "message"]
  end

  def send_google_analytics(click_text)
    response = Faraday.get 'https://www.google-analytics.com/collect?v=1&t=pageview&tid=UA-91261614-2&cid=262b33e7-e442-466b-ac7e-a5ba79785bf6&dp=/click_id/'+click_text
  end
end





