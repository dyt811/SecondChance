#!/usr/bin/env ruby
require 'pry'
require 'shopify_api'
require 'dotenv'
Dotenv.load


class TagCustomers
	attr_accessor :shop_url
	
	# Configure the Shopify Connection
	def initialize 
		@shop_url = "https://#{ENV["SHOPIFY_API_KEY"]}:#{ENV["SHOPIFY_PASSWORD"]}@#{ENV["SHOP"]}.myshopify.com/admin"
		ShopifyAPI::Base.site = @shop_url
	end
	
	# Test the Shopify connection witha SIMPLE GET request
	def test_connection
		return ShopifyAPI::Shop.current
	end		
end

# Called when the file is run on the command line, but not in a required
if __FILE__ == $PROGRAM_NAME
	put TagCustomers.new.test_connection.inspect # Prints the results
end