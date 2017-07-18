
# Loading libraries.
require 'shopify_api'
require 'sinatra'
require 'httparty'
require 'dotenv'
Dotenv.load

class SecondChance < Sinatra::Base
  register React::Sinatra
  attr_reader :tokens
  API_KEY = ENV['API_KEY']
  API_SECRET = ENV['API_SECRET']
  APP_URL = "second-chance.herokuapp.com"
  #nonce = rand(36**32).to_s(36)
  NONCE = "1qaz2wsx3edc"

  def initialize
    @tokens = {}
    @shop = {}
    super
  end

  # Sinatra React part: https://github.com/namusyaka/react-sinatra
  configure do
    React::Sinatra.configure do |config|
    # configures for bundled React.js
    config.use_bundled_react = true
    config.env = ENV['RACK_ENV'] || :development
    config.addon = true

    # The asset should be able to be compiled by your server side runtime.
    # react-sinatra does not transform jsx into js, also ES2015 may not be worked through.
    # config.asset_path = File.join('client', 'dist', 'server.js')
    config.runtime = :execjs
    end
  end


  #Sinatra block. When reaching that URL, do these...

  # Enable sessions to prevent statelessness
  enable :sessions

  # Key Installation Block to install the proper permission for the app.
  get '/install' do
    @shop = request.params['shop']

    # Specify the permission scope.
    # Need to be able to R orders,
    # Need to be able to RW Customers.
    # Need to be able to W draft orders
    scopes = "read_orders,read_products,write_products,read_customers,write_customers, read_draft_orders, write_draft_orders"

    # construct the installation/permission request URL and redirect the merchant
    # Key component: Shop URL, API_Key, Scopes, APP_URL
    install_url = "http://#{@shop}/admin/oauth/authorize?client_id=#{API_KEY}"\
    "&scope=#{scopes}&redirect_uri=https://#{APP_URL}/auth&state=#{NONCE}"

    # redirect to the install_url
    redirect install_url
    log("End of Install", __LINE__)
  end

  # OAuthonication via TOKEN
  get '/auth' do

    log("Reached the beginning of authorization", __LINE__)

    # extract shop data from request parameters
    @shop = request.params['shop']
    session[:shop] = request.params['shop']

    log("Shop: #{@shop}", __LINE__)

    code = request.params['code']
    log("Code: #{code}", __LINE__)

    hmac = request.params['hmac']
    log("HMAC: #{hmac}", __LINE__)

    nonceReply = request.params['state']
    log("State: #{nonceReply}", __LINE__)

    # Perform nonce validation to ensure that it is coming from Shopify
    validate_nonce(nonceReply)
    log("Validated Nonce", __LINE__)

    # perform hmac validation to determine if the request is coming from Shopify
    validate_hmac(hmac,request)
    log("Validated HMAC", __LINE__)

    # if no access token for this particular shop exist,
    # POST the OAuth request and receive the token in the response
    get_shop_access_token(@shop,API_KEY,API_SECRET,code)

    # create webhook for order creation if it doesn't exist
    # create_order_webhook

    # now that the session is activated, redirect to the bulk edit page
    redirect "https://second-chance.herokuapp.com/orders/"
    log("Redirected:", __LINE__)
  end

  # when POST to order creation process.
  post '/SecondChance/webhook/order_create' do
    # inspect hmac value in header and verify webhook
    hmac = request.env['HTTP_X_SHOPIFY_HMAC_SHA256']

    request.body.rewind
    data = request.body.read

    # Inspect HMAC value
    webhook_ok = verify_webhook(hmac, data)

    if webhook_ok
      shop = request.env['HTTP_X_SHOPIFY_SHOP_DOMAIN']
      token = @tokens[shop]

      unless token.nil?
        session = ShopifyAPI::Session.new(shop, token)
        ShopifyAPI::Base.activate_session(session)
      else
        return [403, "You're not authorized to perform this action."]
      end
    else
      return [403, "You're not authorized to perform this action."]
    end


    # parse the request body as JSON data
    json_data = JSON.parse data

    line_items = json_data['line_items']

    line_items.each do |line_item|
      variant_id = line_item['variant_id']

      variant = ShopifyAPI::Variant.find(variant_id)

      variant.metafields.each do |field|
        if field.key == 'ingredients'
          items = field.value.split(',')

          items.each do |item|
            gift_item = ShopifyAPI::Variant.find(item)
            gift_item.inventory_quantity = gift_item.inventory_quantity - 1
            gift_item.save
          end
        end
      end
    end

    return [200, "Webhook notification received successfully."]
  end

  #============================
  # Test Code BLOCK============
  #============================
  get '/' do
    "Hello, World!"
  end

  get '/about' do
    "Welcome to the world of DEATH"
  end

  get '/react/:name' do |name|
    component = react_component('Hello', { name: name }, prerender: true)
    # ...
  end

  get '/react-component' do
    haml :'react-component', layout: true
  end

  get '/react-component-with-server' do
    haml :'react-component-with-server', layout: true
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

  get '/form/' do
    erb :form
  end

  #Retrieve a list of orders and display them.
  get '/orders/:orderID' do
    log("Initiated Individual Order Retrieval:", __LINE__)

    #Read from cookie.
    @shop = session[:shop]
    @token = session[:token]
    log(@shop,__LINE__);

    #Open Session.
    session = ShopifyAPI::Session.new(@shop, @tokens[@shop])
    ShopifyAPI::Base.activate_session(session)

    log(params[:orderID],__LINE__)

    # Get the specific order
    @order = ShopifyAPI::Order.find(params[:orderID])

    # Display all orders
    log("End of ORDER routine", __LINE__)

    # All Data acquired. Time to display them.
    erb :order, { :locals => params }
  end

  get '/orders/?' do
    log("Initiated Orders Retrieval:", __LINE__)

    #Read from cookie.
    @shop = session[:shop]
    log(@shop, __LINE__)
    @token = session[:token]

    log("Creating Session Method", __LINE__)
    session = ShopifyAPI::Session.new(@shop, @tokens[@shop])

    log("Activating Session2", __LINE__)
    ShopifyAPI::Base.activate_session(session)

    log("Session Activated",__LINE__)

    log("Obtaining Orders:", __LINE__)

    # Get orders
    @orders = ShopifyAPI::Order.all

    "Orders Count: #{@orders.count}\n"

    # Display all orders
    log("End of ORDERS routine", __LINE__)

    # All Data acquired. Time to display them.
    erb :orders #, { :locals => params }
  end

  get '/customers/' do
    instantiate_session(@shop)
    customers = get_customers
    show_customers(customers)
    "Customer Count: #{customers.count}\n"
  end

  post '/form/' do
    "You said '#{params[:message]}'"
  end

  get '/secret/' do
    erb :secret
  end

  post '/secret/' do
    params[:secret].reverse
  end

  get '/decrypt/:secret' do
    params[:secret].reverse
  end

  not_found do
    halt 404, 'You have reached the 404 page. Routing not found. Check your Sinatra configuration ruby file.'
  end

  helpers do
    def get_shop_access_token(shop,client_id,client_secret,code)
      if @tokens[shop].nil?
        url = "https://#{shop}/admin/oauth/access_token"

        payload = {client_id: client_id,client_secret: client_secret,code: code}

        response = HTTParty.post(url, body: payload)

        # if the response is successful, obtain the token and store it in a hash
        if response.code == 200
          @tokens[shop] = response['access_token']
          session[:token] = response['access_token']
        else
          return [500, "Something went wrong."]
        end

        instantiate_session(shop)
      end
    end

    def instantiate_session(shop)
      # now that the token is available, instantiate a session
      session = ShopifyAPI::Session.new(shop, @tokens[shop])
      ShopifyAPI::Base.activate_session(session)
    end

    def validate_hmac(hmac,request)
      h = request.params.reject{|k,_| k == 'hmac' || k == 'signature'}
      query = URI.escape(h.sort.collect{|k,v| "#{k}=#{v}"}.join('&'))
      sha = OpenSSL::Digest.new('sha256')

      log("API_SECRET#{API_SECRET}",__LINE__)
      log("query:#{query}",__LINE__)
      log("SHA:#{sha}",__LINE__)

      digest = OpenSSL::HMAC.hexdigest(sha, API_SECRET, query)

      unless (hmac == digest)
        return [403, "Authentication failed. Digest provided was: #{digest}"]
      end
    end

    def validate_nonce(reply)
      unless (reply == "1qaz2wsx3edc")
        return [403, "Authentication failed. Replied nonce provided was: #{reply}"]
      end
    end

    def verify_webhook(hmac, data)
      digest = OpenSSL::Digest.new('sha256')
      calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, API_SECRET, data)).strip

      hmac == calculated_hmac
    end

    def bulk_edit_url
      bulk_edit_url = "https://www.shopify.com/admin/bulk"\
      "?resource_name=ProductVariant"\
      "&edit=metafields.test.ingredients:string"
      return bulk_edit_url
    end

    def create_order_webhook
      # create webhook for order creation if it doesn't exist
      unless ShopifyAPI::Webhook.find(:all).any?
        webhook = {topic: 'orders/create',address: "https://#{APP_URL}/SecondChance/webhook/order_create",format: 'json'}

        ShopifyAPI::Webhook.create(webhook)
      end
    end

    # Function for logging.
    def log(str,line)
      puts "Reached=>#{line}:#{str}"
      #puts "#{__FILE__}:#{__LINE__}:#{str}"
    end

    # Tests the Shopify connection with a simple GET reqeust
    def test_connections
      return ShopifyAPI::Shop.current
    end

    # Download the customers from Shopify
    def get_customers
      return ShopifyAPI::Customer.all
    end

    # Download orders from Shopify
    def get_orders
      return ShopifyAPI::Order.all
    end

    # Show orders
    def show_orders(orders)
      orderList = []
      orders.each do |order|
        puts "Order: #{order.number} = #{order.id}"
        "Order: #{order.number} = #{order.id}"
        orderList << order
      end
    end

    # Show cusotmers
    def show_customers(customers)
      customerList = []
      customers.each do |customer|

        puts "Customer: #{customer.email} = #{customer.id}"
        "Customer: #{customer.email} = #{customer.id}"
        customerList << customer
      end
    end
  end

  error 500 do
    "Sinatra Error Encountered. Check Herokuapp logs"
  end

end

run SecondChance.run!
