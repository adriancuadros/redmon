require 'spec_helper'
require 'sinatra/contrib'

describe "app" do
  include Rack::Test::Methods

  def app
    Redmon::App.new
  end

  def stub_redis_cmd(cmd, *args)
    mock_redis.should_receive(cmd).with(*args).and_return({})
  end

  let(:json) {"application/json;charset=utf-8"}

  describe "GET /" do
    it "should render app" do
      stub_redis_cmd :config, :get, '*'
      get "/"
      last_response.should be_ok
      last_response.body.include?('Redmon')
    end
  end

  describe "POST /config" do
    it "should call redis#config set value" do
      stub_redis_cmd :config, :set, :param, 'value'
      post "/config?param=param&value=value"
      last_response.should be_ok
    end
  end

  describe "GET /cli" do
    let(:command) { URI.encode("keys *") }

    it "should execute the passed command" do
      stub_redis_cmd :keys, '*'
      get URI.encode("/cli?command=keys *")
      last_response.should be_ok
    end

    it "should render an empty list result" do
      redis = mock_redis
      redis.stub(:send).and_return([])

      get "/cli?command=#{command}"
      last_response.should be_ok
      last_response.body.include? Redmon::Redis.empty_result
    end

    it "should render the wrong arguments result" do
      redis = mock_redis
      redis.stub(:send).and_raise(ArgumentError)

      get "/cli?command=#{command}"
      last_response.should be_ok
      last_response.body.include? Redmon::Redis.wrong_number_of_arguments_for(:keys)
    end

    it "should return an unknown result" do
      redis = mock_redis
      redis.stub(:send).and_raise(RuntimeError)

      get "/cli?command=#{command}"
      last_response.should be_ok
      last_response.body.include? Redmon::Redis.unknown(:keys)
    end

    it "should return a connection refused result" do
      redis = mock_redis
      redis.stub(:send).and_raise(Errno::ECONNREFUSED)

      get "/cli?command=#{command}"
      last_response.should be_ok
      last_response.body.include? Redmon::Redis.connection_refused
    end
  end

  describe "GET /stats" do
    it "should render a single json result" do
      stub_redis_cmd :zrange, Redmon::Redis.stats_key, -1, -1
      get "/stats"
      last_response.should be_ok
      last_response.headers["Content-Type"].should == json
    end

    it "should request the correct # of historical info entries" do
      stub_redis_cmd :zrange, Redmon::Redis.stats_key, -666, -1
      get "/stats?count=666"
      last_response.should be_ok
    end
  end

end