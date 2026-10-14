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

  describe "boroughs" do
    def import_with_boroughs(*rows)
      import(*rows, header: "borough,sub_county,ward,budget_ksh")
    end

    it "creates the boroughs and assigns their subcounties" do
      importer = import_with_boroughs("Western Borough,Dagoretti South,Mutuini,230000000",
                                      "western borough,Dagoretti North,Kilimani,100000000",
                                      "Northern Borough,Westlands,Parklands,95000000")

      expect(importer.errors).to be_empty
      expect(importer.sets_created).to eq 2
      expect(budget.sets.count).to eq 2

      western = budget.sets.find_by!(slug: "western-borough")
      expect(western.groups.map(&:name)).to match_array ["Dagoretti South", "Dagoretti North"]
      expect(budget.groups.find_by!(slug: "westlands").set.name).to eq "Northern Borough"
    end

    it "reuses existing boroughs and moves subcounties to the borough of the file" do
      western = create(:budget_set, budget: budget, name: "Western Borough")
      northern = create(:budget_set, budget: budget, name: "Northern Borough")
      group = create(:budget_group, budget: budget, set: northern, name: "Dagoretti South")

      importer = import_with_boroughs("Western Borough,Dagoretti South,Mutuini,230000000")

      expect(importer.sets_created).to eq 0
      expect(group.reload.set).to eq western
      expect(importer.warnings).to eq [
        "Line 2: Dagoretti South moved from Northern Borough to Western Borough"
      ]
    end

    it "leaves subcounties without borough when the borough is blank" do
      importer = import_with_boroughs(",Westlands,Parklands,95000000")

      expect(importer.errors).to be_empty
      expect(budget.sets.count).to eq 0
      expect(budget.groups.find_by!(slug: "westlands").set).to be nil
    end
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
