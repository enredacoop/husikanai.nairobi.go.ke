# Imports sectors and subsectors from a CSV file with the columns sector and
# sub_sector. The sub_sector column is optional, so a row with only a sector
# creates a main sector without subsectors.
#
# Existing sectors and subsectors (matched by name, ignoring case) are reused,
# so the same file can be imported again.
class Nairobi::SectorsImporter
  COLUMNS = %w[sector sub_sector].freeze
  REQUIRED_COLUMNS = %w[sector].freeze

  attr_reader :path, :errors, :sectors_created, :sub_sectors_created

  def initialize(path)
    @path = path
    @errors = []
    @sectors_created = 0
    @sub_sectors_created = 0
  end

  def import
    rows = Nairobi::CsvFile.parse(path)
    missing_columns = REQUIRED_COLUMNS - rows.headers.compact

    if missing_columns.any?
      errors << "Missing columns: #{missing_columns.join(", ")}"
    else
      rows.each.with_index(2) do |row, line|
        import_row(Nairobi::CsvFile.clean(row), line) unless row.fields.all?(&:blank?)
      end
    end

    self
  rescue CSV::MalformedCSVError => e
    errors << "Invalid CSV file: #{e.message}"
    self
  end

  private

    def import_row(data, line)
      return errors << "Line #{line}: sector is required" if data["sector"].blank?

      Sector.transaction do
        sector = find_or_create(data["sector"])
        find_or_create(data["sub_sector"], parent: sector) if data["sub_sector"].present?
      end
    rescue ActiveRecord::RecordInvalid => e
      errors << "Line #{line} (#{data["sector"]} / #{data["sub_sector"]}): " \
                "#{e.record.errors.full_messages.to_sentence}"
    end

    def find_or_create(name, parent: nil)
      Sector.where(parent: parent).find_by("LOWER(name) = ?", name.downcase) ||
        Sector.create!(name: name, parent: parent).tap do
          parent ? @sub_sectors_created += 1 : @sectors_created += 1
        end
    end
end
