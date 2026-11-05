load Rails.root.join("app", "controllers", "budgets", "executions_controller.rb")

module Budgets
  class ExecutionsController
    PER_PAGE = 10

    def show
      authorize! :read_executions, @budget
      @statuses = Milestone::Status.all
      @headings = @budget.headings.sort_by(&:name)
      @investments = paginated_investments
      @investments_by_heading = @investments.group_by(&:heading)
    end

    private

      def paginated_investments
        investments = @budget.investments.winners.where(id: investments_with_milestones)
        investments = investments.where(heading_id: params[:heading_id]) if params[:heading_id].present?
        investments = investments.tagged_with(params[:milestone_tag]) if params[:milestone_tag].present?
        investments = investments.with_latest_milestone_status_id(params[:status]) if params[:status].present?

        investments.includes(:heading, milestones: :translations)
                   .joins(heading: :translations)
                   .where(budget_heading_translations: { locale: I18n.locale })
                   .order("budget_heading_translations.name", :id)
                   .page(params[:page]).per(PER_PAGE)
      end

      def investments_with_milestones
        Milestone.joins(:translations)
                 .where(milestoneable_type: "Budget::Investment")
                 .select(:milestoneable_id)
      end
  end
end
