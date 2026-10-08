require "rails_helper"

describe Admin::BudgetHeadings::FormComponent do
  it "does not limit the length of the money amount" do
    heading = create(:budget_heading)

    render_inline Admin::BudgetHeadings::FormComponent.new(heading, path: "/", action: :edit)

    expect(page).to have_field "Money amount"
    expect(page.find_field("Money amount")[:maxlength]).to be nil
  end
end
