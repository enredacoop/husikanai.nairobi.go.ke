load Rails.root.join("app", "controllers", "budgets", "investments_controller.rb")

module Budgets
  class InvestmentsController
    before_action :load_group, only: :index

    private

      def load_group
        if params[:group_id].present?
          @group = @budget.groups.find_by_slug_or_id!(params[:group_id])
          params[:group_id] = @group.id
        end
      end
  end
end
