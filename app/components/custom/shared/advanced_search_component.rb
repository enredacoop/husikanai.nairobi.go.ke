class Shared::AdvancedSearchComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "shared", "advanced_search_component.rb")

class Shared::AdvancedSearchComponent
  private

    def expanded?
      advanced_search.present? || selected_group_id.present? || selected_heading_id.present? ||
        selected_sector_id.present?
    end

    def filters_row?
      headings_filters? || sectors_filters?
    end

    # Subcounty and ward filters are only shown in the investments of budgets with several wards
    def budget
      return unless controller_path == "budgets/investments" && params[:budget_id].present?

      @budget ||= Budget.find_by_slug_or_id(params[:budget_id])
    end

    def headings_filters?
      budget.present? && !budget.single_heading?
    end

    def groups
      @groups ||= budget.groups.includes(:translations, headings: :translations).sort_by(&:name)
    end

    def selected_heading
      return if params[:heading_id].blank?

      @selected_heading ||= budget.headings.find_by_slug_or_id(params[:heading_id])
    end

    def selected_heading_id
      selected_heading&.id if budget
    end

    def selected_group_id
      return unless budget

      if params[:group_id].present?
        budget.groups.find_by_slug_or_id(params[:group_id])&.id
      else
        selected_heading&.group_id
      end
    end

    def group_options
      options_for_select(groups.map { |group| [group.name, group.id] }, selected_group_id)
    end

    def heading_options
      grouped_options = groups.map do |group|
        options = group.headings.sort_by(&:name).map do |heading|
          [heading.name, heading.id, { data: { parent_id: group.id }}]
        end

        [group.name, options]
      end

      grouped_options_for_select(grouped_options, selected_heading_id)
    end

    def sectors_filters?
      budget.present? && sectors.any?
    end

    def sub_sectors_filter?
      sectors.any? { |sector| sector.sub_sectors.any? }
    end

    def sectors
      @sectors ||= Sector.main.includes(:sub_sectors).to_a
    end

    def selected_sub_sector
      return if params[:sub_sector_id].blank?

      @selected_sub_sector ||= sectors.flat_map(&:sub_sectors).find do |sub_sector|
        sub_sector.id.to_s == params[:sub_sector_id].to_s
      end
    end

    def selected_sector_id
      return unless budget

      if params[:sector_id].present?
        sectors.find { |sector| sector.id.to_s == params[:sector_id].to_s }&.id
      else
        selected_sub_sector&.parent_id
      end
    end

    def sector_options
      options_for_select(sectors.map { |sector| [sector.name, sector.id] }, selected_sector_id)
    end

    def sub_sector_options
      grouped_options = sectors.select { |sector| sector.sub_sectors.any? }.map do |sector|
        options = sector.sub_sectors.map do |sub_sector|
          [sub_sector.name, sub_sector.id, { data: { parent_id: sector.id }}]
        end

        [sector.name, options]
      end

      grouped_options_for_select(grouped_options, selected_sub_sector&.id)
    end
end
