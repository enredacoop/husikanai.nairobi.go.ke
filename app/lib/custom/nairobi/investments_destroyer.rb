# Permanently deletes budget investments (including hidden ones) and the
# records referencing them, so projects can be imported again from scratch.
class Nairobi::InvestmentsDestroyer
  TYPE = "Budget::Investment".freeze

  attr_reader :investments

  def initialize(budget = nil)
    @investments = Budget::Investment.with_hidden
    @investments = @investments.where(budget: budget) if budget
  end

  def count
    investments.count
  end

  def destroy!
    ids = investments.ids

    ActiveRecord::Base.transaction do
      # Polymorphic records that are not destroyed with the investment
      ProgressBar.unscoped.where(progressable_type: TYPE, progressable_id: ids).delete_all
      Comment.unscoped.where(commentable_type: TYPE, commentable_id: ids).delete_all
      Vote.unscoped.where(votable_type: TYPE, votable_id: ids).delete_all
      Flag.unscoped.where(flaggable_type: TYPE, flaggable_id: ids).delete_all
      Notification.unscoped.where(notifiable_type: TYPE, notifiable_id: ids).delete_all

      # Records referencing the investment by investment_id
      Budget::Ballot::Line.where(investment_id: ids).delete_all
      Budget::ReclassifiedVote.where(investment_id: ids).delete_all

      # Milestones, translations, images, documents, map locations, follows,
      # valuator assignments, related contents and taggings are destroyed here
      Budget::Investment.with_hidden.where(id: ids).find_each(&:really_destroy!)
    end

    ids.size
  end
end
