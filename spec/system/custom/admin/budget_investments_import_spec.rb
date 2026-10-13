require "rails_helper"

describe "Import of investment projects from a CSV file", :admin do
  let(:budget) { create(:budget) }

  before do
    group = create(:budget_group, budget: budget, name: "Dagoretti South")
    create(:budget_heading, group: group, name: "Mutuini")
  end

  def csv_file(*rows)
    Tempfile.new(["projects", ".csv"]).tap do |file|
      file.write(CSV.generate do |csv|
        csv << Nairobi::ProjectsImporter::COLUMNS
        rows.each { |row| csv << row }
      end)
      file.close
    end
  end

  def project_row(name:, ward: "Mutuini", sector: "", status: "Ongoing")
    [sector, "", name, "Dagoretti South", ward, "Mutuini", "Description of #{name}", "", "", "", "",
     "1000000", "", "2024-02", "", "50", status, "NCCG"]
  end

  scenario "Upload a CSV file from the budget investments page" do
    create(:sector, name: "Health")

    visit admin_budget_budget_investments_path(budget)
    click_link "Import projects"

    expect(page).to have_content "sector,sub_sector,project_name"
    expect(page).to have_link "Download a template"

    file = csv_file(project_row(name: "Mutuini clinic", sector: "health"),
                    project_row(name: "Rocket", sector: "Space"),
                    project_row(name: "Atlantis bridge", ward: "Atlantis"))
    attach_file "Import projects", file.path, make_visible: true

    expect(page).to have_content "Created: 2. Updated: 0. Errors: 1. Warnings: 1."
    expect(page).to have_content "Line 4: ward \"Atlantis\""
    expect(page).to have_content "Line 3: sector \"Space\" does not match; left blank"

    clinic = budget.investments.find_by!(title: "Mutuini clinic")
    expect(clinic.sector.name).to eq "Health"
    expect(clinic.author).to be_administrator
    expect(clinic.author.email).not_to eq "admin@consul.dev"
    expect(budget.investments.find_by!(title: "Rocket").sector).to be nil

    click_link "See the investment projects"

    expect(page).to have_content "Mutuini clinic"
    expect(page).to have_content "Rocket"
  end

  scenario "The file input is hidden behind the import button" do
    visit new_admin_budget_investments_import_path(budget)

    expect(page).to have_css "label.button input[type='file'].show-for-sr", visible: :all
    expect(page).to have_css "label.button", text: "Import projects"
    expect(page).not_to have_button "Import projects"
  end

  scenario "Import projects link in the budget page" do
    visit admin_budget_path(budget)

    within(".budgets-links") { click_link "Import projects" }

    expect(page).to have_css "h2", text: "#{budget.name} - Import projects"
  end

  scenario "Files which are not CSV files are rejected" do
    file = Tempfile.new(["projects", ".pdf"])
    file.write("not a csv")
    file.close

    visit new_admin_budget_investments_import_path(budget)
    attach_file "Import projects", file.path, make_visible: true

    expect(page).to have_content "The file must be a CSV file"
    expect(budget.investments.count).to eq 0
  end

  scenario "Download the template" do
    visit new_admin_budget_investments_import_path(budget)

    expect(page).to have_link "Download a template",
                              href: template_admin_budget_investments_import_path(budget)
  end
end
