# Imports the subcounties (groups) and wards (headings) of a budget from a CSV
# file with the columns sub_county, ward and budget_ksh.
#
# Existing subcounties and wards (matched by name) are reused, and the budget
# of existing wards is updated, so the same file can be imported again.
class Nairobi::WardsImporter
  COLUMNS = %w[sub_county ward budget_ksh].freeze
  REQUIRED_COLUMNS = %w[sub_county ward].freeze

  attr_reader :budget, :path, :errors, :warnings, :groups_created, :headings_created, :headings_updated

  def self.template
    CSV.generate do |csv|
      csv << COLUMNS
      csv << ["Dagoretti South", "Mutuini", "230000000"]
      csv << ["Dagoretti South", "Ngando", "230000000"]
    end
  end

  def initialize(budget, path)
    @budget = budget
    @path = path
    @errors = []
    @warnings = []
    @groups_created = 0
    @headings_created = 0
    @headings_updated = 0
  end

  def import
    I18n.with_locale(I18n.default_locale) do
      rows = Nairobi::CsvFile.parse(path)
      missing_columns = REQUIRED_COLUMNS - rows.headers.compact

      if missing_columns.any?
        errors << "Missing columns: #{missing_columns.join(", ")}"
      else
        rows.each.with_index(2) do |row, line|
          import_row(Nairobi::CsvFile.clean(row), line) unless row.fields.all?(&:blank?)
        end
      end
    end

    self
  rescue CSV::MalformedCSVError => e
    errors << "Invalid CSV file: #{e.message}"
    self
  end

  def imported?
    groups_created + headings_created + headings_updated > 0
  end

  private

    def import_row(data, line)
      if data["sub_county"].blank? || data["ward"].blank?
        return errors << "Line #{line}: sub_county and ward are required"
      end

      group = find_group(data["sub_county"]) || budget.groups.new(name: data["sub_county"])
      new_group = group.new_record?
      heading = (find_heading(group, data["ward"]) unless new_group) ||
                Budget::Heading.new(group: group, name: data["ward"])
      new_heading = heading.new_record?
      price = amount(data["budget_ksh"], line)

      heading.price = price || heading.price || 0

      Budget::Heading.transaction do
        group.save!
        heading.group = group
        heading.save!
      end

      @groups_created += 1 if new_group
      new_heading ? @headings_created += 1 : @headings_updated += 1
    rescue ActiveRecord::RecordInvalid => e
      errors << "Line #{line} (#{data["sub_county"]} / #{data["ward"]}): " \
                "#{e.record.errors.full_messages.to_sentence}"
    end

    def find_group(name)
      budget.groups.joins(:translations).find_by("LOWER(budget_group_translations.name) = ?", name.downcase)
    end

    def find_heading(group, name)
      group.headings.joins(:translations)
           .find_by("LOWER(budget_heading_translations.name) = ?", name.downcase)
    end

    def amount(value, line)
      return if value.blank?

      number = BigDecimal(value.delete(", "), exception: false)

      if number
        number.round.to_i
      else
        warnings << "Line #{line}: budget_ksh \"#{value}\" is not a valid amount; left unchanged"
        nil
      end
    end
end
