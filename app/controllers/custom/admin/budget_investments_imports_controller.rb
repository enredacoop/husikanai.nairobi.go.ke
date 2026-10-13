class Admin::BudgetInvestmentsImportsController < Admin::BaseController
  include FeatureFlags

  MAX_FILE_SIZE = 10.megabytes
  EXTENSIONS = %w[.csv .tsv .txt].freeze

  feature_flag :budgets

  before_action :load_budget

  def new
  end

  def create
    file = params[:file]

    if file.blank?
      flash.now[:error] = t("admin.budget_investments_imports.create.no_file")
    elsif EXTENSIONS.exclude?(File.extname(file.original_filename).downcase)
      flash.now[:error] = t("admin.budget_investments_imports.create.invalid_format")
    elsif file.size > MAX_FILE_SIZE
      flash.now[:error] = t("admin.budget_investments_imports.create.too_big",
                            size: helpers.number_to_human_size(MAX_FILE_SIZE))
    else
      @importer = Nairobi::ProjectsImporter.new(@budget, file.path, author: current_user).import
    end

    render :new
  end

  def template
    send_data Nairobi::ProjectsImporter.template,
              filename: "projects_template.csv",
              type: "text/csv"
  end

  private

    def load_budget
      @budget = Budget.find_by_slug_or_id! params[:budget_id]
    end
end
