module Qernel::Plugins
  module Merit
    class ProducerAdapter < Adapter
      def inject!
        full_load_hours = participant.full_load_hours

        if ! full_load_hours || full_load_hours.nan?
          full_load_seconds = full_load_hours = 0.0
        else
          full_load_seconds = full_load_hours * 3600
        end

        @converter[:full_load_hours]   = full_load_hours
        @converter[:full_load_seconds] = full_load_seconds

        @converter[:marginal_costs]    = participant.marginal_costs
        @converter[:number_of_units]   = participant.number_of_units
        @converter[:profitability]     = participant.profitability

        @converter[:profit_per_mwh_electricity] =
          participant.profit_per_mwh_electricity

        @converter.demand =
          full_load_seconds *
          @converter.input_capacity *
          participant.number_of_units
      end

      private

      def producer_attributes
        attrs = super

        marginal_cost = @converter.variable_costs_per(:mwh_electricity)

        attrs[:marginal_costs] =
          if marginal_cost && marginal_cost.nan?
            Float::INFINITY
          else
            marginal_cost
          end

        attrs[:output_capacity_per_unit] =
          @converter.electricity_output_conversion * @converter.input_capacity

        attrs[:fixed_costs_per_unit] =
          @converter.send(:fixed_costs)

        attrs[:fixed_om_costs_per_unit] =
          @converter.send(:fixed_operation_and_maintenance_costs_per_year)

        attrs
      end

      def producer_class
        ::Merit::DispatchableProducer
      end
    end # ProducerAdapter
  end # Merit
end
