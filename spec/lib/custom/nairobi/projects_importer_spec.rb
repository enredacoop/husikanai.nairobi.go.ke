require "rails_helper"

describe Nairobi::ProjectsImporter do
  let(:budget) { create(:budget, :finished) }
  let(:group) { create(:budget_group, budget: budget, name: "Dagoretti South") }
  let!(:heading) { create(:budget_heading, group: group, name: "Mutuini", price: 1_000) }
  let(:header) do
    %w[sector sub_sector project_name sub_county ward location objectives description project_cost_ksh
       actual_cost_ksh start_date end_date implementation_pct status funds].join("\t")
  end
  let(:row) do
    ["Business and Hustler Opportunities", "Markets and Trading Services",
     "Construction of 10 no. of markets", "Dagoretti South / Mutuini", "Mutuini", "Mutuini",
     "To provide additional decent trading spaces", "Construction of Market", "242592913", "194000000",
     "2024-02", "2025-02", "85", "Delayed", "NCCG"].join("\t")
  end

  before { create(:administrator, user: create(:user, email: "admin@consul.dev")) }

  def import(*lines)
    file = Tempfile.new(["projects", ".csv"])
    file.write([header, *lines].join("\n"))
    file.close
    Nairobi::ProjectsImporter.new(budget, file.path).import
  end

  it "imports a project as a winning investment" do
    importer = import(row)

    expect(importer.errors).to be_empty
    expect(importer.created).to eq 1

    investment = budget.investments.last
    expect(investment.title).to eq "Construction of 10 no. of markets"
    expect(investment.description).to eq "Construction of Market"
    expect(investment.objectives).to eq "To provide additional decent trading spaces"
    expect(investment.heading).to eq heading
    expect(investment.group).to eq group
    expect(investment.author.email).to eq "admin@consul.dev"
    expect(investment.location).to eq "Mutuini"
    expect(investment.price).to eq 242_592_913
    expect(investment.actual_cost).to eq 194_000_000
    expect(investment.start_date).to eq Date.new(2024, 2, 1)
    expect(investment.end_date).to eq Date.new(2025, 2, 1)
    expect(investment.funding_source).to eq "NCCG"
    expect(investment.sector.name).to eq "Business and Hustler Opportunities"
    expect(investment.sub_sector.name).to eq "Markets and Trading Services"
    expect(investment.sub_sector.parent).to eq investment.sector
    expect(investment).to be_feasible
    expect(investment).to be_valuation_finished
    expect(investment).to be_selected
    expect(investment).to be_winner
    expect(investment.primary_progress_bar.percentage).to eq 85
    expect(investment.milestones.last.status.name).to eq "Delayed"
  end

  it "creates the predefined milestone statuses" do
    import(row)

    expect(Milestone::Status.pluck(:name)).to match_array ["Awarded", "Not started", "Ongoing", "Delayed",
                                                           "Stalled", "Substantially Complete", "Completed",
                                                           "Operational", "Terminated"]
    expect(Milestone::Status.find_by!(name: "Delayed").description)
      .to eq "Under implementation, but behind the planned schedule"
  end

  it "restores predefined statuses which were deleted" do
    create(:milestone_status, name: "Stalled").destroy!

    Nairobi::ProjectsImporter.create_milestone_statuses

    expect(Milestone::Status.where(name: "Stalled").count).to eq 1
    expect(Milestone::Status.with_deleted.where(name: "Stalled").count).to eq 1
  end

  it "matches statuses ignoring the case and rejects unknown ones" do
    footbridge = row.sub("Construction of 10 no. of markets", "Footbridge").sub("\tDelayed\t", "\tPaused\t")
    importer = import(row.sub("\tDelayed\t", "\tsubstantially complete\t"), footbridge)

    expect(budget.investments.last.milestones.last.status.name).to eq "Substantially Complete"
    expect(importer.errors.size).to eq 1
    expect(importer.errors.first).to include "unknown status \"Paused\""
  end

  it "sets the ward budget to the sum of its projects" do
    other = row.sub("Construction of 10 no. of markets", "Mutuini footbridge").sub("242592913", "7407087")

    import(row, other)

    expect(heading.reload.price).to eq 250_000_000
  end

  it "updates existing projects instead of duplicating them" do
    import(row)
    importer = import(row.sub("\t85\tDelayed", "\t100\tCompleted"))

    expect(importer.updated).to eq 1
    expect(budget.investments.count).to eq 1

    investment = budget.investments.last
    expect(investment.primary_progress_bar.percentage).to eq 100
    expect(investment.milestones.map { |milestone| milestone.status.name }).to eq %w[Delayed Completed]
    expect(Sector.count).to eq 2
  end

  it "accepts comma separated files" do
    file = Tempfile.new(["projects", ".csv"])
    file.write([header.tr("\t", ","), CSV.generate_line(row.split("\t")).chomp].join("\n"))
    file.close

    importer = Nairobi::ProjectsImporter.new(budget, file.path).import

    expect(importer.errors).to be_empty
    expect(budget.investments.count).to eq 1
  end

  it "reports rows with unknown wards or invalid data" do
    importer = import(row.sub("\tMutuini\tMutuini\t", "\tAtlantis\tMutuini\t"),
                      row.sub("2024-02", "February"))

    expect(importer.errors.size).to eq 2
    expect(importer.errors.first).to include "Line 2: ward \"Atlantis\""
    expect(importer.errors.last).to start_with "Line 3"
    expect(budget.investments.count).to eq 0
    expect(heading.reload.price).to eq 1_000
  end
end
