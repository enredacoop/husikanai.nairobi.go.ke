module SectorsHelper
  def sector_select_options
    Sector.main.map { |sector| [sector.name, sector.id] }
  end

  # Sub-sectors grouped by sector; each option knows its sector so the list
  # can be filtered when a sector is selected
  def sub_sector_select_options(selected = nil)
    grouped_options = Sector.main.includes(:sub_sectors).map do |sector|
      options = sector.sub_sectors.map do |sub_sector|
        [sub_sector.name, sub_sector.id, { data: { sector_id: sector.id }}]
      end

      [sector.name, options]
    end

    grouped_options_for_select(grouped_options, selected)
  end
end
