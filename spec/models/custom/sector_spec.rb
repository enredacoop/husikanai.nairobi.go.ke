require "rails_helper"

describe Sector do
  it "is valid" do
    expect(build(:sector)).to be_valid
    expect(build(:sector, :sub_sector)).to be_valid
  end

  it "requires a unique name within the same parent" do
    markets = create(:sector, name: "Markets")
    create(:sector, name: "Trading", parent: markets)

    expect(build(:sector, name: "markets")).not_to be_valid
    expect(build(:sector, name: "trading", parent: markets)).not_to be_valid
    expect(build(:sector, name: "Trading", parent: create(:sector))).to be_valid
  end

  it "does not allow sub-sectors of sub-sectors" do
    expect(build(:sector, parent: create(:sector, :sub_sector))).not_to be_valid
  end

  it "cannot be deleted when it has sub-sectors or investments" do
    sector = create(:sector)
    create(:sector, parent: sector)

    expect(sector.destroy).to be false

    used = create(:sector)
    create(:budget_investment, sector: used)

    expect(used.destroy).to be false
  end

  describe ".find_or_create_by_name!" do
    it "finds sectors ignoring the case and creates them otherwise" do
      sector = create(:sector, name: "Health")

      expect(Sector.find_or_create_by_name!("HEALTH")).to eq sector
      expect { Sector.find_or_create_by_name!("Clinics", parent: sector) }.to change {
        sector.sub_sectors.count
      }.by(1)
    end
  end
end

describe Budget::Investment do
  describe "project fields" do
    let(:sector) { create(:sector) }

    it "requires the sub-sector to belong to the sector" do
      sub_sector = create(:sector, parent: sector)

      expect(build(:budget_investment, sector: sector, sub_sector: sub_sector)).to be_valid
      expect(build(:budget_investment, sector: create(:sector), sub_sector: sub_sector)).not_to be_valid
      expect(build(:budget_investment, sector: sub_sector)).not_to be_valid
    end

    it "requires the end date to be after the start date" do
      expect(build(:budget_investment, start_date: "2024-02-01", end_date: "2025-02-01")).to be_valid
      expect(build(:budget_investment, start_date: "2025-02-01", end_date: "2024-02-01")).not_to be_valid
    end

    it "has translatable target and performance indicator" do
      investment = create(:budget_investment, target: "Decent trading spaces",
                                              performance_indicator: "No. of markets")

      expect(Budget::Investment.translated_attribute_names).to include(:target, :performance_indicator)
      expect(investment.reload.target).to eq "Decent trading spaces"
      expect(investment.performance_indicator).to eq "No. of markets"
    end
  end
end
