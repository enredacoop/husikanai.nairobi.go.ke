require "csv"

# Reads CSV files exported from spreadsheets: comma or tab separated, in
# UTF-8 (with or without BOM) or Windows-1252, with case insensitive headers.
module Nairobi::CsvFile
  def self.parse(path)
    content = read(path)
    col_sep = content.lines.first.to_s.include?("\t") ? "\t" : ","

    CSV.parse(content, headers: true, col_sep: col_sep, header_converters: ->(h) { h.to_s.strip.downcase })
  end

  def self.read(path)
    content = File.binread(path).delete_prefix("\xEF\xBB\xBF".b).force_encoding("UTF-8")
    content.valid_encoding? ? content : content.force_encoding("Windows-1252").encode("UTF-8")
  end

  def self.clean(row)
    row.to_h.compact.transform_values { |value| value.to_s.strip.chomp(";").strip }
  end
end
