require 'spec_helper'

describe Api::V2::ScenariosController do
  before do
    @scenario = Factory :scenario
    @homepage_scenario = Preset.new({:in_start_menu => true})
  end

  describe "GET index.xml" do
    it "should return all scenarios" do
      get :index, :format => :xml
      response.should be_success
      assigns(:scenarios).should == [@scenario]
    end
  end

  describe "GET homepage.xml" do
    it "should return the scenarios visible in homepage" do
      Preset.stub!(:all) {[@homepage_scenario]}
      get :homepage, :format => :xml
      response.should be_success
      assigns(:scenarios).map(&:attributes).should == [@homepage_scenario.to_scenario.attributes]
    end
  end

  describe "GET show.xml" do
    it "should return the scenarios visible in homepage" do
      get :show, :id => @scenario.id, :format => :xml
      response.should be_success
      assigns(:scenario).should == @scenario
    end
  end

  describe "Creating scenario from api_scenario" do
    before do
      @api_scenario = Factory(:scenario)
    end

    it "should create a new scenario with values from api_scenario" do
      put :create, 'scenario' => {'title' => 'foo bar', 'api_session_id' => @api_scenario.id.to_s }

      assigns(:scenario).title.should == 'foo bar'
    end
  end
end