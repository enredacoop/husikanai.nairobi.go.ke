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
#
# Values which don't match (sector, sub-sector, status, amounts, dates...) are
# left blank and reported as warnings. Rows whose ward doesn't match are not
# imported, since every investment must belong to a ward.
class Nairobi::ProjectsImporter
  AUTHOR_EMAIL = "admin@consul.dev".freeze
  COLUMNS = %w[sector sub_sector project_name sub_county ward location description performance_indicator
               target implementing_agency contractor project_cost_ksh actual_cost_ksh start_date end_date
               implementation_pct status funds].freeze
  REQUIRED_COLUMNS = %w[project_name ward description].freeze
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

  # CSV with the expected columns and an example row
  def self.template
    CSV.generate do |csv|
      csv << COLUMNS
      csv << ["Business and Hustler Opportunities", "Markets and Trading Services",
              "Construction of 10 no. of markets", "Dagoretti South", "Mutuini", "Mutuini",
              "Construction of Market", "No. of markets constructed", "10 markets",
              "Department of Business and Hustler Opportunities", "Mutuini Builders Ltd",
              "242592913", "194000000", "2024-02", "2025-02", "85", "Delayed", "NCCG"]
    end
  end

  def self.find_status(name, with_deleted: false)
    statuses = with_deleted ? Milestone::Status.with_deleted : Milestone::Status
    statuses.find_by("LOWER(name) = ?", name.to_s.downcase)
  end

  def initialize(budget, path, author: nil)
    @budget = budget
    @path = path
    @author = author
    @errors = []
    @warnings = []
    @created = 0
    @updated = 0
  end

  def import
    self.class.create_milestone_statuses

    I18n.with_locale(:en) do
      parsed_rows = rows
      missing_columns = REQUIRED_COLUMNS - parsed_rows.headers.compact

      if missing_columns.any?
        errors << "Missing columns: #{missing_columns.join(", ")}"
      else
        parsed_rows.each.with_index(2) do |row, line|
          import_row(row, line) unless row.fields.all?(&:blank?)
        end
        update_heading_prices
      end
    end

    self
  rescue CSV::MalformedCSVError => e
    errors << "Invalid CSV file: #{e.message}"
    self
  end

  def imported
    created + updated
  end

  private

    def rows
      Nairobi::CsvFile.parse(path)
    end

    def import_row(row, line)
      data = Nairobi::CsvFile.clean(row)
      heading = find_heading(data["ward"], data["sub_county"], line)
      return unless heading

      investment = find_investment(data["project_name"], heading)
      new_record = investment.new_record?

      Budget::Investment.transaction do
        investment.update!(investment_attributes(data, heading, line))
        update_progress(investment, data["implementation_pct"], line)
        update_status(investment, data["status"], line)
      end

      new_record ? @created += 1 : @updated += 1
      touched_headings << heading
    rescue ActiveRecord::RecordInvalid => e
      errors << "Line #{line} (#{data&.dig("project_name")}): #{e.record.errors.full_messages.to_sentence}"
    end

    def investment_attributes(data, heading, line)
      sector = find_sector(data["sector"], nil, line, "sector")
      sub_sector = find_sector(data["sub_sector"], sector, line, "sub_sector") if sector

      if sector.nil? && data["sub_sector"].present?
        blank_value_warning(line, "sub_sector", data["sub_sector"])
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
        price: amount(data["project_cost_ksh"], line, "project_cost_ksh"),
        actual_cost: amount(data["actual_cost_ksh"], line, "actual_cost_ksh"),
        start_date: month(data["start_date"], line, "start_date"),
        end_date: month(data["end_date"], line, "end_date"),
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
        errors << "Line #{line}: ward \"#{ward}\" (#{sub_county}) not found or ambiguous; " \
                  "the project was not imported"
        nil
      end
    end

    def find_sector(name, parent, line, field)
      return if name.blank?

      sector = Sector.where(parent: parent).find_by("LOWER(name) = ?", name.downcase)
      blank_value_warning(line, field, name) unless sector
      sector
    end

    def blank_value_warning(line, field, value)
      warnings << "Line #{line}: #{field} \"#{value}\" does not match; left blank"
    end

    def find_investment(title, heading)
      budget.investments.where(heading: heading).joins(:translations)
            .find_by(budget_investment_translations: { title: title, locale: "en" }) ||
        budget.investments.new
    end

    def update_progress(investment, value, line)
      return if value.blank?

      percentage = Float(value.delete("%"), exception: false)
      return blank_value_warning(line, "implementation_pct", value) unless percentage

      progress_bar = investment.progress_bars.primary.first_or_initialize
      progress_bar.update!(percentage: percentage.round.clamp(ProgressBar::RANGE))
    end

    def update_status(investment, name, line)
      return if name.blank?

      unless MILESTONE_STATUSES.keys.any? { |valid_name| valid_name.casecmp?(name) }
        return blank_value_warning(line, "status", name)
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

    def amount(value, line, field)
      return if value.blank?

      number = BigDecimal(value.delete(", "), exception: false)

      if number
        number.round.to_i
      else
        blank_value_warning(line, field, value)
        nil
      end
    end

    def month(value, line, field)
      return if value.blank?

      if value.match?(/\A\d{4}-\d{1,2}\z/)
        year, month = value.split("-").map(&:to_i)
        Date.new(year, month, 1)
      else
        Date.iso8601(value)
      end
    rescue Date::Error
      blank_value_warning(line, field, value)
      nil
    end
end
