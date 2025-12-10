load Rails.root.join("app", "models", "budget.rb")

class Budget < ApplicationRecord
    CURRENCY_SYMBOLS = %w[€ $ £ ¥ KSh].freeze
end