load Rails.root.join("app", "models", "budget", "group.rb")

class Budget
  class Group
    belongs_to :set, optional: true

    validate :set_belongs_to_budget

    private

      def set_belongs_to_budget
        if set.present? && set.budget_id != budget_id
          errors.add(:set_id, :invalid)
        end
      end
  end
end
