class Budgets::Investments::ProjectDetailsComponent < ApplicationComponent
  attr_reader :investment

  def initialize(investment)
    @investment = investment
  end

  def render?
    details.any?
  end

  private

    def details
      @details ||= {
        sector: sector,
        status: status&.name,
        implementation: implementation,
        performance_indicator: investment.performance_indicator.presence,
        price: (money(investment.price) if show_costs?),
        actual_cost: (money(investment.actual_cost) if show_costs? && investment.actual_cost.present?),
        start_date: month(investment.start_date),
        end_date: month(investment.end_date),
        implementing_agency: investment.implementing_agency.presence,
        contractor: investment.contractor.presence,
        funding_source: investment.funding_source.presence
      }.compact
    end

    def sector
      [investment.sector&.name, investment.sub_sector&.name].compact.join(" › ").presence
    end

    def status
      investment.milestones.published.with_status.order_by_publication_date.last&.status
    end

    def implementation
      percentage = investment.primary_progress_bar&.percentage
      "#{percentage}%" if percentage
    end

    # Same rule Consul uses to show the price of an investment
    def show_costs?
      investment.should_show_price?
    end

    def money(amount)
      investment.budget.formatted_amount(amount)
    end

    def month(date)
      l(date, format: :month_year) if date
    end
end
