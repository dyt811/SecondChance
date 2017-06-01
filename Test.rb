
# Loading libraries. 
require 'shopify_api'
require 'sinatra'
require 'httparty'
require 'dotenv'
Dotenv.load

class SecondChance < Sinatra::Base
  attr_reader :tokens
  API_KEY = ENV['API_KEY']
  API_SECRET = ENV['API_SECRET']
  APP_URL = "ca3da5ac.ngrok.io"

  def initialize
    @tokens = {}
    super
  end

  #Sinatra block. When reaching that URL, do these...

  #============================
  # Test Code BLOCK============
  #============================
  get '/' do
    "Hellow, World!"
  end

  get '/about' do
    "Welcome to the world of DEATH"
  end

  get '/hello/:name' do
    params[:name]
    "Hello there, #{params[:name]}"
  end

  get '/hello/:name/:city' do    
    "Hello there, #{params[:name]} from #{params[:city]}"
  end

  get '/more/*' do    
    "Hello there, #{params[:splat]}"
  end

  get '/form' do
    erb :form
  end

  post '/form' do
    "You said '#{params[:message]}'"
  end

  get '/secret' do 
    erb :secret
  end

  post '/secret' do 
    params[:secret].reverse
  end

  get '/decrypt/:secret' do 
    params[:secret].reverse
  end

  not_found do 
    halt 404, 'not found'
  end

end

run SecondChance.run!
