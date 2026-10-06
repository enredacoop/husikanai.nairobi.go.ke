class Admin::Budgets::GroupComponent < ApplicationComponent
  attr_reader :group, :heading_level

  def initialize(group, heading_level: 4)
    @group = group
    @heading_level = heading_level
  end

  private

    def budget
      group.budget
    end

    def action(...)
      render Admin::ActionComponent.new(...)
    end
end
