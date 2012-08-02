module Api
  module V2
    class ApiScenariosController < BaseController
      layout 'api'

      around_filter :disable_gc, :only => [:update, :show]
      before_filter :find_model, :only => [:destroy, :user_values, :input_data]

      # This action is still active but old. We should probably move it to a protected
      # namespace
      #
      def index
        @api_scenarios = Scenario.order('id DESC').limit(100)

        respond_to do |format|
          format.html {  }
          format.json { render :json => @api_scenarios, :callback => params[:callback] }
        end
      end

      # This action is used by the ETE clients to create a new scenario.
      # The response is a simple JSON object like this:
      #
      # {"api_scenario":{"area_code":"nl","end_year":2030,"id":7554,"use_fce":false,"user_values":{}}}
      #
      # The important field is the id, that the clients will have to use on the following #show requests
      #
      def new
        attributes = Request.new_attributes(params[:settings])
        @api_scenario = Scenario.new(attributes)
        @api_scenario.scenario_id = params[:settings][:scenario_id] rescue nil
        @api_scenario.save!
        respond_to do |format|
          format.html { redirect_to api_v2_scenario_url(@api_scenario.id)}
          format.json { render :json => @api_scenario, :callback => params[:callback] }
        end
      end
      # create does the same like new, except that it is a POST request
      alias_method :create, :new

      # This is the main API entry point. Most operations happen through this method.
      # The ETM slider updates and gquery requests are processed here. See ApiRequest.
      #
      # Available parameters:
      # * id: id of the scenario we're querying
      # * input: a hash with input_id as key and value as value
      # * r: a string that joins gquery ids with ApiRequest::GQUERY_KEY_SEPARATOR
      # * result: array of gquery keys/ids
      # * reset: will first clear the scenario attributes
      #
      # The purpose of the shorter r parameter is to have shorter URLs. IE will truncate
      # too long JSONP requests. If we hadn't the cross-domain issue we could send
      # everything with a simple JSON POST request.
      #
      def show
        @api_request = Request.response(params)
        # We can probably get rid of this extra api_scenario assignment
        @api_scenario = @api_request.scenario
        @api_response = @api_request.response

        respond_to do |format|
          format.html
          format.json { render :json => @api_response, :callback => params[:callback] }
        end
      end
      # update does the same like show, but it is a POST request
      alias_method :update, :show

      # This action is reachable through #index.html. We should move it to a protected
      # namespace.
      #
      def destroy
        @api_scenario.destroy
        redirect_to api_scenarios_url
      end

      # This action is called by the ETM backbone application on every page request. It responds
      # with a JSON hash with the various values of the sliders
      #
      # TODO: it would be nice to move as much code as possible into a separate model
      #
      def user_values
        @api_request = Request.response(params)
        values = @api_request.scenario.input_values

        respond_to do |format|
          format.json do
            render :json => values, :callback => params[:callback]
          end
        end
      end

      # Similar to user_values, but returns only the subset of the inputs we need
      # and uses the input key as hash key
      def input_data
        gql = @api_scenario.gql(prepare: true)
        inputs = params[:inputs] || []
        out = {}
        inputs.each do |key|
          input = Input.get(key) rescue nil
          if input
            out[key] = input.client_values(gql)
            out[key][:user_value] = @api_scenario.user_values[input.lookup_id] rescue nil
          end
        end
        render :json => out, :callback => params[:callback]
      end

      protected

      def find_model
        @api_scenario = Scenario.find(params[:id])
      end
    end
  end
end