class Sector < ApplicationRecord
  belongs_to :parent, class_name: "Sector", optional: true, inverse_of: :sub_sectors
  has_many :sub_sectors, -> { order(:name) }, class_name: "Sector", foreign_key: :parent_id,
                                              inverse_of: :parent, dependent: :restrict_with_error
  has_many :investments, class_name: "Budget::Investment", dependent: :restrict_with_error
  has_many :sub_sector_investments, class_name: "Budget::Investment", foreign_key: :sub_sector_id,
                                    inverse_of: :sub_sector, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :parent_id, case_sensitive: false }
  validate :parent_is_a_main_sector

  scope :main, -> { where(parent_id: nil).order(:name) }

  def main?
    parent_id.nil?
  end

  def self.find_or_create_by_name!(name, parent: nil)
    where(parent: parent).where("LOWER(name) = ?", name.downcase).first || create!(name: name, parent: parent)
  end

  private

    def parent_is_a_main_sector
      errors.add(:parent_id, :invalid) if parent && !parent.main?
    end
end
