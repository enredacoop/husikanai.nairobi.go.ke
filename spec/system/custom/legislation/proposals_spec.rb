require "rails_helper"

describe "Legislation Proposals" do
  let(:process)  { create(:legislation_process) }
  let(:proposal) { create(:legislation_proposal) }

  scenario "Show link to process on show" do
    create(:legislation_proposal, legislation_process_id: process.id)

    visit legislation_process_proposal_path(proposal.process, proposal)

    within(".process-proposal") do
      expect(page).to have_content("COLLABORATIVE POLICY AND LEGISLATION PROCESS")
      expect(page).to have_link(process.title)
    end
  end
end
