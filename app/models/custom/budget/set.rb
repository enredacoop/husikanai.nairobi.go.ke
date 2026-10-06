class Budget
  class Set < ApplicationRecord
    include Sluggable

    translates :name, touch: true
    include Globalizable

    translation_class_delegate :budget

    class Translation
      validate :name_uniqueness_by_budget

      def name_uniqueness_by_budget
        if budget.sets.joins(:translations)
                 .where(name: name)
                 .where.not("budget_set_translations.budget_set_id": budget_set_id).any?
          errors.add(:name, I18n.t("errors.messages.taken"))
        end
      end
    end

    belongs_to :budget

    has_many :groups, dependent: :nullify

    validates_translation :name, presence: true
    validates :budget_id, presence: true
    validates :slug, presence: true, format: /\A[a-z0-9\-_]+\z/

    def self.sort_by_name
      all.sort_by(&:name)
    end

    private

      def generate_slug?
        slug.nil? || budget.drafting?
      end
  end
end
