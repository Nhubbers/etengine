module Api
  module V2
    class AreasController < BaseController
      respond_to :xml

      def index
        respond_with(Etsource::Dataset.region_codes.map{|c| Area.get c})
      end

      def show
        respond_with(@area = Area.get(params[:id]))
      end
    end
  end
end