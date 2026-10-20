class Budgets::Investments::FormComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "budgets", "investments", "form_component.rb")

class Budgets::Investments::FormComponent
  private

    # The subcounty select only filters the wards; just the ward is submitted
    def groups
      @groups ||= budget.groups.includes(:translations, headings: :translations).sort_by(&:name)
    end

    def group_options
      options_for_select(groups.map { |group| [group.name, group.id] }, investment.heading&.group_id)
    end

    def heading_options
      grouped_options = groups.map do |group|
        options = group.headings.sort_by(&:name).map do |heading|
          [heading.name, heading.id, { data: { parent_id: group.id }}]
        end

        [group.name, options]
      end

      grouped_options_for_select(grouped_options, investment.heading_id)
    end
end
