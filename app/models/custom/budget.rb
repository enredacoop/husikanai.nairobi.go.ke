load Rails.root.join("app", "models", "budget.rb")

class Budget < ApplicationRecord
  CURRENCY_SYMBOLS = %w[€ $ £ ¥ KSh].freeze

  has_many :sets, dependent: :destroy

  def investments_milestone_tags
    ActsAsTaggableOn::Tag.joins(:taggings)
                         .where(taggings: { taggable_type: "Budget::Investment",
                                            context: "milestone_tags",
                                            taggable_id: investments.winners.select(:id) })
                         .distinct.order(:name).pluck(:name)
  end

  alias_method :consul_investments_orders, :investments_orders

  # Finished budgets can also be sorted by price, since there's no longer a
  # decision the order could influence
  def investments_orders
    if finished? && !hide_money?
      %w[random price]
    else
      consul_investments_orders
    end
  end
end
