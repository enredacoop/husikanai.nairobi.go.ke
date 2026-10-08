load Rails.root.join("app", "models", "milestone.rb")

class Milestone
  # The milestone status is shown in cached views of the milestoneable
  after_commit -> { milestoneable&.touch unless milestoneable&.destroyed? }
end
