require "csv"

# Imports Nairobi City County projects (already in progress) as winning
# investments of a budget. Expected columns:
#
#   sector, sub_sector, project_name, sub_county, ward, location, description,
#   performance_indicator, target, implementing_agency, contractor,
#   project_cost_ksh, actual_cost_ksh, start_date, end_date,
#   implementation_pct, status, funds
#
# Running it again updates the existing projects (matched by name and ward).
class Nairobi::ProjectsImporter
  AUTHOR_EMAIL = "admin@consul.dev".freeze
  MILESTONE_STATUSES = {
    "Awarded" => "Contract awarded, not started yet",
    "Not started" => "Not started yet",
    "Ongoing" => "Under implementation",
    "Delayed" => "Under implementation, but behind the planned schedule",
    "Stalled" => "Works stopped",
    "Substantially Complete" => "Almost finished, usually between 90% and 99%",
    "Completed" => "Finished",
    "Operational" => "Already in operation",
    "Terminated" => "Contract cancelled"
  }.freeze

  attr_reader :budget, :path, :errors, :warnings, :created, :updated

  # Creates the predefined statuses (restoring them if they were deleted)
  # and updates their descriptions
  def self.create_milestone_statuses
    MILESTONE_STATUSES.each do |name, description|
      status = find_status(name, with_deleted: true) || Milestone::Status.new(name: name)
      status.restore! if status.deleted?
      status.update!(description: description)
    end
  end

  def self.find_status(name, with_deleted: false)
    statuses = with_deleted ? Milestone::Status.with_deleted : Milestone::Status
    statuses.find_by("LOWER(name) = ?", name.to_s.downcase)
  end

  def initialize(budget, path)
    @budget = budget
    @path = path
    @errors = []
    @warnings = []
    @created = 0
    @updated = 0
  end

  def import
    self.class.create_milestone_statuses

    I18n.with_locale(:en) do
      rows.each.with_index(2) { |row, line| import_row(row, line) }
      update_heading_prices
    end

    self
  end

  private

    def rows
      content = File.read(path, encoding: "bom|utf-8")
      col_sep = content.lines.first.to_s.include?("\t") ? "\t" : ","

      CSV.parse(content, headers: true, col_sep: col_sep, header_converters: ->(h) { h.to_s.strip.downcase })
         .reject { |row| row.fields.all?(&:blank?) }
    end

    def import_row(row, line)
      data = row.to_h.transform_values { |value| value.to_s.strip.chomp(";").strip }
      heading = find_heading(data["ward"], data["sub_county"], line)
      return unless heading

      investment = find_investment(data["project_name"], heading)
      new_record = investment.new_record?

      Budget::Investment.transaction do
        investment.update!(investment_attributes(data, heading))
        update_progress(investment, data["implementation_pct"])
        update_status(investment, data["status"])
      end

      new_record ? @created += 1 : @updated += 1
      touched_headings << heading
    rescue ActiveRecord::RecordInvalid, ArgumentError => e
      errors << "Line #{line} (#{data&.dig("project_name")}): #{e.message}"
    end

    def investment_attributes(data, heading)
      sector = Sector.find_or_create_by_name!(data["sector"]) if data["sector"].present?

      if sector && data["sub_sector"].present?
        sub_sector = Sector.find_or_create_by_name!(data["sub_sector"], parent: sector)
      end

      {
        title: data["project_name"],
        description: data["description"],
        performance_indicator: data["performance_indicator"].presence,
        target: data["target"].presence,
        implementing_agency: data["implementing_agency"].presence,
        contractor: data["contractor"].presence,
        heading: heading,
        author: author,
        terms_of_service: "1",
        location: data["location"].presence,
        price: amount(data["project_cost_ksh"]),
        actual_cost: amount(data["actual_cost_ksh"]),
        start_date: month(data["start_date"]),
        end_date: month(data["end_date"]),
        funding_source: data["funds"].presence,
        sector: sector,
        sub_sector: sub_sector,
        feasibility: "feasible",
        valuation_finished: true,
        selected: true,
        winner: true
      }
    end

    def find_heading(ward, sub_county, line)
      subcounty = sub_county.to_s.split("/").first.to_s.strip
      candidates = budget.headings.joins(:translations)
                         .where("LOWER(budget_heading_translations.name) = ?", ward.to_s.downcase)
                         .distinct.to_a

      if candidates.size > 1
        candidates.select! { |heading| heading.group.name.casecmp?(subcounty) }
      end

      if candidates.size == 1
        heading = candidates.first
        if subcounty.present? && !heading.group.name.casecmp?(subcounty)
          warnings << "Line #{line}: ward #{ward} belongs to #{heading.group.name}, not to #{subcounty}"
        end
        heading
      else
        errors << "Line #{line}: ward \"#{ward}\" (#{sub_county}) not found or ambiguous"
        nil
      end
    end

    def find_investment(title, heading)
      budget.investments.where(heading: heading).joins(:translations)
            .find_by(budget_investment_translations: { title: title, locale: "en" }) ||
        budget.investments.new
    end

    def update_progress(investment, value)
      return if value.blank?

      percentage = Float(value.delete("%")).round.clamp(ProgressBar::RANGE)
      investment.progress_bars.primary.first_or_initialize.update!(percentage: percentage)
    end

    def update_status(investment, name)
      return if name.blank?

      unless MILESTONE_STATUSES.keys.any? { |valid_name| valid_name.casecmp?(name) }
        raise ArgumentError, "unknown status \"#{name}\" (valid: #{MILESTONE_STATUSES.keys.join(", ")})"
      end

      status = self.class.find_status(name)
      last_status = investment.milestones.with_status.order_by_publication_date.last&.status

      unless last_status == status
        investment.milestones.create!(status: status, publication_date: Date.current)
      end
    end

    def update_heading_prices
      touched_headings.uniq.each do |heading|
        total = budget.investments.where(heading: heading).sum(:price)
        heading.update!(price: total) if total.positive?
      end
    end

    def touched_headings
      @touched_headings ||= []
    end

    def author
      @author ||= User.find_by!(email: AUTHOR_EMAIL)
    end

    def amount(value)
      return if value.blank?

      BigDecimal(value.delete(", ")).round.to_i
    end

    def month(value)
      return if value.blank?

      if value.match?(/\A\d{4}-\d{1,2}\z/)
        year, month = value.split("-").map(&:to_i)
        Date.new(year, month, 1)
      else
        Date.iso8601(value)
      end
    end
end
