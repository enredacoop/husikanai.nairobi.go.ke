require "rails_helper"

describe Nairobi::ProjectsImporter do
  let(:budget) { create(:budget, :finished) }
  let(:group) { create(:budget_group, budget: budget, name: "Dagoretti South") }
  let!(:heading) { create(:budget_heading, group: group, name: "Mutuini", price: 1_000) }
  let(:columns) do
    %w[sector sub_sector project_name sub_county ward location description performance_indicator target
       implementing_agency contractor project_cost_ksh actual_cost_ksh start_date end_date
       implementation_pct status funds]
  end
  let(:header) { columns.join("\t") }
  let(:row) do
    ["Business and Hustler Opportunities", "Markets and Trading Services",
     "Construction of 10 no. of markets", "Dagoretti South / Mutuini", "Mutuini", "Mutuini",
     "Construction of Market", "No. of markets constructed", "10 markets",
     "Department of Business and Hustler Opportunities", "Mutuini Builders Ltd", "242592913", "194000000",
     "2024-02", "2025-02", "85", "Delayed", "NCCG"].join("\t")
  end

  before do
    create(:administrator, user: create(:user, email: "admin@consul.dev"))
    sector = create(:sector, name: "Business and Hustler Opportunities")
    create(:sector, parent: sector, name: "Markets and Trading Services")
  end

  def csv_file(*lines)
    Tempfile.new(["projects", ".csv"]).tap do |file|
      file.write([header, *lines].join("\n"))
      file.close
    end
  end

  def import(*lines)
    Nairobi::ProjectsImporter.new(budget, csv_file(*lines).path).import
  end

  it "imports a project as a winning investment" do
    importer = import(row)

    expect(importer.errors).to be_empty
    expect(importer.created).to eq 1

    investment = budget.investments.last
    expect(investment.title).to eq "Construction of 10 no. of markets"
    expect(investment.description).to eq "Construction of Market"
    expect(investment.performance_indicator).to eq "No. of markets constructed"
    expect(investment.target).to eq "10 markets"
    expect(investment.implementing_agency).to eq "Department of Business and Hustler Opportunities"
    expect(investment.contractor).to eq "Mutuini Builders Ltd"
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

  it "matches statuses ignoring the case and leaves unknown ones blank" do
    footbridge = row.sub("Construction of 10 no. of markets", "Footbridge").sub("\tDelayed\t", "\tPaused\t")
    importer = import(row.sub("\tDelayed\t", "\tsubstantially complete\t"), footbridge)

    expect(importer.errors).to be_empty
    expect(importer.created).to eq 2
    expect(budget.investments.find_by!(title: "Footbridge").milestones).to be_empty
    markets = budget.investments.find_by!(title: "Construction of 10 no. of markets")
    expect(markets.milestones.last.status.name).to eq "Substantially Complete"
    expect(importer.warnings).to eq ["Line 3: status \"Paused\" does not match; left blank"]
  end

  it "leaves sectors and sub-sectors blank when they do not match" do
    unknown_sector = row.sub("Business and Hustler Opportunities", "Space exploration")
                        .sub("Construction of 10 no. of markets", "Rocket")
    unknown_sub_sector = row.sub("Markets and Trading Services", "Street vendors")
                            .sub("Construction of 10 no. of markets", "Stalls")

    importer = import(unknown_sector, unknown_sub_sector)

    expect(importer.errors).to be_empty
    expect(Sector.count).to eq 2

    rocket = budget.investments.find_by!(title: "Rocket")
    expect(rocket.sector).to be nil
    expect(rocket.sub_sector).to be nil

    stalls = budget.investments.find_by!(title: "Stalls")
    expect(stalls.sector.name).to eq "Business and Hustler Opportunities"
    expect(stalls.sub_sector).to be nil

    expect(importer.warnings).to eq [
      "Line 2: sector \"Space exploration\" does not match; left blank",
      "Line 2: sub_sector \"Markets and Trading Services\" does not match; left blank",
      "Line 3: sub_sector \"Street vendors\" does not match; left blank"
    ]
  end

  it "leaves invalid amounts, dates and percentages blank" do
    invalid_row = row.sub("2024-02", "February").sub("194000000", "unknown").sub("\t85\t", "\tabout half\t")
    importer = import(invalid_row)

    expect(importer.errors).to be_empty

    investment = budget.investments.last
    expect(investment.start_date).to be nil
    expect(investment.actual_cost).to be nil
    expect(investment.primary_progress_bar).to be nil
    expect(importer.warnings.size).to eq 3
  end

  it "uses the given author" do
    author = create(:administrator).user

    Nairobi::ProjectsImporter.new(budget, csv_file(row).path, author: author).import

    expect(budget.investments.last.author).to eq author
  end

  it "reports missing required columns" do
    columns.delete("ward")

    importer = import(row)

    expect(importer.errors).to eq ["Missing columns: ward"]
    expect(budget.investments.count).to eq 0
  end

  it "reads files encoded in Windows-1252" do
    file = Tempfile.new(["projects", ".csv"], binmode: true)
    file.write([header, row.sub("Mutuini Builders Ltd", "Muñoz Builders")].join("\n").encode("Windows-1252"))
    file.close

    importer = Nairobi::ProjectsImporter.new(budget, file.path).import

    expect(importer.errors).to be_empty
    expect(budget.investments.last.contractor).to eq "Muñoz Builders"
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
  end

  it "accepts comma separated files" do
    file = Tempfile.new(["projects", ".csv"])
    file.write([header.tr("\t", ","), CSV.generate_line(row.split("\t")).chomp].join("\n"))
    file.close

    importer = Nairobi::ProjectsImporter.new(budget, file.path).import

    expect(importer.errors).to be_empty
    expect(budget.investments.count).to eq 1
  end

  it "does not import rows with unknown wards or invalid projects" do
    importer = import(row.sub("\tMutuini\tMutuini\t", "\tAtlantis\tMutuini\t"),
                      row.sub("Construction of Market", ""))

    expect(importer.errors.size).to eq 2
    expect(importer.errors.first).to include "Line 2: ward \"Atlantis\""
    expect(importer.errors.last).to start_with "Line 3"
    expect(budget.investments.count).to eq 0
    expect(heading.reload.price).to eq 1_000
  end
end
