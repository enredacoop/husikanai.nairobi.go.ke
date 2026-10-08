load Rails.root.join("app", "models", "budget", "investment.rb")

class Budget
  class Investment
    translates :objectives, touch: true

    belongs_to :sector, optional: true
    belongs_to :sub_sector, class_name: "Sector", optional: true

    validates :actual_cost, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    validate :sector_is_a_main_sector
    validate :sub_sector_belongs_to_sector
    validate :end_date_after_start_date

    def self.apply_filters_and_search(_budget, params, current_filter = nil)
      investments = all
      investments = investments.send(current_filter)             if current_filter.present?
      investments = investments.by_group(params[:group_id])      if params[:group_id].present?
      investments = investments.by_heading(params[:heading_id])  if params[:heading_id].present?
      investments = investments.search(params[:search])          if params[:search].present?
      investments = investments.filter_by(params[:advanced_search])
      investments
    end

    private

      def sector_is_a_main_sector
        errors.add(:sector_id, :invalid) if sector && !sector.main?
      end

      def sub_sector_belongs_to_sector
        errors.add(:sub_sector_id, :invalid) if sub_sector && sub_sector.parent_id != sector_id
      end

      def end_date_after_start_date
        if start_date && end_date && end_date < start_date
          errors.add(:end_date, :invalid)
        end
      end
  end
end
