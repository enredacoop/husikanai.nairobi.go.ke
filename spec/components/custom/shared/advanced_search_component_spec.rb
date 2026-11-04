require "rails_helper"

describe Shared::AdvancedSearchComponent do
  let(:budget) { create(:budget) }
  let(:westlands) { create(:budget_group, budget: budget, name: "Westlands") }
  let(:embakasi) { create(:budget_group, budget: budget, name: "Embakasi East") }
  let!(:parklands) { create(:budget_heading, group: westlands, name: "Parklands") }

  before do
    create(:budget_heading, group: westlands, name: "Kangemi")
    create(:budget_heading, group: embakasi, name: "Upper Savannah")
  end

  def render_in_investments(params = {})
    with_request_url(Rails.application.routes.url_helpers.budget_investments_path(budget, params)) do
      with_controller_class(Budgets::InvestmentsController) do
        render_inline Shared::AdvancedSearchComponent.new
      end
    end
  end

  it "shows subcounty and ward filters in the investments of a budget" do
    render_in_investments

    expect(page).to have_select "Subcounty", options: ["All subcounties", "Embakasi East", "Westlands"]
    expect(page).to have_select "Ward",
                                with_options: ["All wards", "Kangemi", "Parklands", "Upper Savannah"]
    expect(page).not_to have_css "select option[selected]"
    expect(page).to have_css "#heading_id optgroup[label='Westlands'] option[data-parent-id]", text: "Kangemi"
    expect(page.find("option", text: "Kangemi")["data-parent-id"]).to eq westlands.id.to_s
    expect(page).to have_css "[aria-expanded='false']", visible: :all
  end

  it "applies the ward and its subcounty when filtering by ward" do
    render_in_investments(heading_id: parklands.id)

    expect(page).to have_select "Subcounty", selected: "Westlands"
    expect(page).to have_select "Ward", selected: "Parklands"
    expect(page).to have_css "[aria-expanded='true']", visible: :all
  end

  it "applies the subcounty when filtering by subcounty" do
    render_in_investments(group_id: embakasi.id)

    expect(page).to have_select "Subcounty", selected: "Embakasi East"
    expect(page).not_to have_css "#heading_id option[selected]"
    expect(page).to have_css "[aria-expanded='true']", visible: :all
  end

  it "does not show the filters for budgets with a single ward" do
    single = create(:budget)
    create(:budget_heading, budget: single)

    with_request_url(Rails.application.routes.url_helpers.budget_investments_path(single)) do
      with_controller_class(Budgets::InvestmentsController) do
        render_inline Shared::AdvancedSearchComponent.new
      end
    end

    expect(page).not_to have_select "Subcounty"
    expect(page).not_to have_select "Ward"
  end

  context "with SDG enabled" do
    before do
      Setting["feature.sdg"] = true
      Setting["sdg.process.budgets"] = true
      Setting["sdg.process.proposals"] = true
    end

    it "does not show the SDG filters in the investments of budgets with several wards" do
      render_in_investments

      expect(page).not_to have_select "By SDG"
      expect(page).not_to have_select "By target"
      expect(page).to have_css ".search-filters-row > .filter", count: 2
    end

    it "keeps the SDG filters in other sections" do
      with_request_url "/proposals" do
        with_controller_class(ProposalsController) do
          render_inline Shared::AdvancedSearchComponent.new
        end
      end

      expect(page).to have_select "By SDG"
      expect(page).not_to have_css ".search-filters-row"
    end
  end

  describe "sector filters" do
    let!(:health) { create(:sector, name: "Health") }
    let!(:clinics) { create(:sector, parent: health, name: "Clinics") }

    before do
      create(:sector, name: "Water")
      create(:sector, parent: health, name: "Hospitals")
    end

    it "shows sector and sub-sector filters in the investments of a budget" do
      render_in_investments

      expect(page).to have_select "Sector", options: ["All sectors", "Health", "Water"]
      expect(page).to have_select "Sub-sector", options: ["All sub-sectors", "Clinics", "Hospitals"]
      expect(page.find("option", text: "Clinics")["data-parent-id"]).to eq health.id.to_s
      expect(page).not_to have_css "select option[selected]"
    end

    it "applies the sub-sector and its sector when filtering by sub-sector" do
      render_in_investments(sub_sector_id: clinics.id)

      expect(page).to have_select "Sector", selected: "Health"
      expect(page).to have_select "Sub-sector", selected: "Clinics"
      expect(page).to have_css "[aria-expanded='true']", visible: :all
    end

    it "shows the sector filters in budgets with a single ward" do
      single = create(:budget)
      create(:budget_heading, budget: single)

      with_request_url(Rails.application.routes.url_helpers.budget_investments_path(single)) do
        with_controller_class(Budgets::InvestmentsController) do
          render_inline Shared::AdvancedSearchComponent.new
        end
      end

      expect(page).to have_select "Sector"
      expect(page).not_to have_select "Ward"
    end

    it "does not show the sub-sector filter when there are no sub-sectors" do
      Sector.where.not(parent_id: nil).delete_all

      render_in_investments

      expect(page).to have_select "Sector"
      expect(page).not_to have_select "Sub-sector"
    end

    it "does not show the sector filters outside budget investments" do
      with_request_url "/proposals" do
        with_controller_class(ProposalsController) do
          render_inline Shared::AdvancedSearchComponent.new
        end
      end

      expect(page).not_to have_select "Sector"
    end
  end

  it "does not show the filters outside budget investments" do
    with_request_url "/proposals" do
      with_controller_class(ProposalsController) do
        render_inline Shared::AdvancedSearchComponent.new
      end
    end

    expect(page).not_to have_select "Subcounty"
  end
end
