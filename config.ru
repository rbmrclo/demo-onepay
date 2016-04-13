require 'digest'
require 'uri'
require 'cgi'
require 'openssl'
require 'sinatra'

class App < Sinatra::Base

  get '/' do
    @merchant        = "ROBBIE"
    @merchant_ref    = "#{Time.now.to_i}"
    @access_code     = ENV.fetch("ACCESS_CODE", "123456")
    @amount          = 10_000_000.to_s
    @currency        = "VND"
    @order_info      = "test order"
    @customer_email  = "test@example.haxxor"
    @ip_address      = "192.168.0.1"
    @language        = "vn"
    @return_url      = "http://localhost:9393/return_url"

    erb :form
  end

  post '/order' do
    GATEWAY_URL   = "https://mtf.onepay.vn/onecomm-pay/vpc.op" # sandbox url
    SECURE_SECRET = [ ENV.fetch("SECURE_SECRET", "s3cr3tk3y") ]

    query = {
      'AgainLink'          => 'onepay.vn',
      'Title'              => 'onepay.vn',
      'vpc_AccessCode'     => params[:access_code],
      'vpc_Amount'         => params[:amount],
      'vpc_Command'        => 'pay',
      'vpc_Currency'       => params[:currency],
      'vpc_Customer_Email' => params[:customer_email],
      'vpc_Locale'         => params[:language],
      'vpc_MerchTxnRef'    => params[:merchant_ref],
      'vpc_Merchant'       => params[:merchant],
      'vpc_OrderInfo'      => params[:order_info],
      'vpc_ReturnURL'      => params[:return_url],
      'vpc_TicketNo'       => params[:ip_address],
      'vpc_Version'        => '2'
    }

    hash_data    = query.reject { |k, _| !k.start_with? 'vpc_' }.collect { |k, v| "#{k}=#{v}" }.join("&")
    secure_hash  = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), SECURE_SECRET.pack("H*"), hash_data).upcase
    request_data = query.collect { |k, v| "#{k}=#{CGI.escape(v)}" }.join("&")
    vpc_url      = [GATEWAY_URL, "?", request_data, "&vpc_SecureHash=", secure_hash].join

    redirect vpc_url
  end

  get '/return_url' do
    @amount         = params["vpc_Amount"]
    @currency       = params["vpc_CurrencyCode"]
    @command        = params["vpc_Command"]
    @merchant_ref   = params["vpc_MerchTxnRef"]
    @transaction_no = params["vpc_TransactionNo"]
    @order_info     = params["vpc_OrderInfo"]
    @locale         = params["vpc_Locale"]
    @secure_hash    = params["vpc_SecureHash"]

    erb :summary
  end

end

run App
