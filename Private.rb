#!/usr/bin/env ruby
require 'pry'
require 'shopify_api'
require 'dotenv'
Dotenv.load

class TagCustomers
	attr_accessor :shop_url

	# Configure Private App Conneciotn
	def initialize		
	    @shop_url = "https://#{ENV["SHOPIFY_API_KEY"]}:#{ENV["SHOPIFY_PASSWORD"]}@#{ENV["SHOP"]}.myshopify.com/admin"
    	ShopifyAPI::Base.site = @shop_url
	end

	# Tests the Shopify connection with a simple GET reqeust
	def test_connections
		return ShopifyAPI::Shop.current
	end

	# Download the customers from Shopify
	def customers
		ShopifyAPI::Customer.all
	end

	# Download orders from Shopify
	def orders 
		ShopifyAPI::Order.all
	end


	# Tag repeat ucstomer with the tag "repeat"
	def tag_repeat_customers
		tagged_customers = []
		customers.each do |customer|
			if customer.orders_count > 1
				unless customer.tags.include?("repeat")
					customer.tags +="repeat"
					customer.save
				end
				tagged_customers << customer
			end		
		end	
	end

		# Tag repeat ucstomer with the tag "repeat"
	def show_orders
		orderList = []		
		orders.each do |order|
			
			puts "Order: #{order.number} = #{order.id}"
			orderList << order
		end	
	end

	def orderConversion(TargetOrderID)
		orders.
		
	end

end


# Called when the file is run ont eh command line but not in a quired
# Also provide feedback of execution. 

if __FILE__ == $PROGRAM_NAME
	TagCustomers.new

	connectted = TagCustomers.new.test_connections
	puts "Connection: #{connectted}\n"
	puts "Customers Count: #{ShopifyAPI::Customer.count}\n"	
	puts "Orders Count: #{ShopifyAPI::Order.count}\n"

	TagCustomers.new.show_orders

	tagged = TagCustomers.new.tag_repeat_customers
	puts "Tagged #{tagged.length} customers with 'repeat'"
end