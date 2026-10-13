require "rails_helper"

describe Nairobi::WardsImporter do
  let(:budget) { create(:budget, :drafting) }

  def import(*rows, header: "sub_county,ward,budget_ksh")
    file = Tempfile.new(["wards", ".csv"])
    file.write([header, *rows].join("\n"))
    file.close
    Nairobi::WardsImporter.new(budget, file.path).import
  end

  it "creates the subcounties and wards with their budget" do
    importer = import("Dagoretti South,Mutuini,230000000",
                      "Dagoretti South,Ngando,\"120,000,000\"",
                      "Westlands,Parklands,95000000")

    expect(importer.errors).to be_empty
    expect(importer.groups_created).to eq 2
    expect(importer.headings_created).to eq 3

    dagoretti = budget.groups.find_by!(slug: "dagoretti-south")
    expect(dagoretti.headings.map(&:name)).to match_array %w[Mutuini Ngando]
    expect(dagoretti.headings.find_by!(slug: "ngando").price).to eq 120_000_000
    expect(budget.headings.find_by!(slug: "parklands").group.name).to eq "Westlands"
  end

  it "reuses existing subcounties and wards and updates their budget" do
    group = create(:budget_group, budget: budget, name: "Dagoretti South")
    create(:budget_heading, group: group, name: "Mutuini", price: 1)

    importer = import("dagoretti south,MUTUINI,230000000", "Dagoretti South,Ngando,120000000")

    expect(importer.groups_created).to eq 0
    expect(importer.headings_created).to eq 1
    expect(importer.headings_updated).to eq 1
    expect(budget.groups.count).to eq 1
    expect(budget.headings.find_by!(slug: "mutuini").price).to eq 230_000_000
  end

  it "keeps the budget when it is not a valid amount" do
    group = create(:budget_group, budget: budget, name: "Westlands")
    create(:budget_heading, group: group, name: "Parklands", price: 500)

    importer = import("Westlands,Parklands,lots", "Westlands,Kangemi,")

    expect(importer.errors).to be_empty
    expect(budget.headings.find_by!(slug: "parklands").price).to eq 500
    expect(budget.headings.find_by!(slug: "kangemi").price).to eq 0
    expect(importer.warnings).to eq ["Line 2: budget_ksh \"lots\" is not a valid amount; left unchanged"]
  end

  it "reports rows without subcounty or ward" do
    importer = import(",Mutuini,1000", "Westlands,,1000")

    expect(importer.errors).to eq ["Line 2: sub_county and ward are required",
                                   "Line 3: sub_county and ward are required"]
    expect(budget.groups.count).to eq 0
  end

  it "reports missing columns" do
    importer = import("Westlands", header: "sub_county")

    expect(importer.errors).to eq ["Missing columns: ward"]
  end

  it "accepts tab separated files with a budget per ward" do
    importer = import("Westlands\tParklands\t95000000", header: "sub_county\tward\tbudget_ksh")

    expect(importer.headings_created).to eq 1
    expect(budget.headings.last.price).to eq 95_000_000
  end
end
