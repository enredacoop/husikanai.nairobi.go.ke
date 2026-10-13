require "rails_helper"

describe "Investments import template" do
  it "downloads a CSV file with the expected columns" do
    budget = create(:budget)
    sign_in(create(:administrator).user)

    get template_admin_budget_investments_import_path(budget)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq "text/csv"
    expect(response.headers["Content-Disposition"]).to include "projects_template.csv"
    expect(CSV.parse(response.body).first).to eq Nairobi::ProjectsImporter::COLUMNS
  end

  it "is not available for users who are not administrators" do
    sign_in(create(:user))

    get template_admin_budget_investments_import_path(create(:budget))

    expect(response).not_to have_http_status(:ok)
  end
end
