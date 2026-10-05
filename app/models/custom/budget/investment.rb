load Rails.root.join("app", "models", "budget", "investment.rb")

class Budget
  class Investment
    def self.apply_filters_and_search(_budget, params, current_filter = nil)
      investments = all
      investments = investments.send(current_filter)             if current_filter.present?
      investments = investments.by_group(params[:group_id])      if params[:group_id].present?
      investments = investments.by_heading(params[:heading_id])  if params[:heading_id].present?
      investments = investments.search(params[:search])          if params[:search].present?
      investments = investments.filter_by(params[:advanced_search])
      investments
    end
  end
end
