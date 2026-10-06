class Admin::BudgetSetsController < Admin::BaseController
  include Translatable
  include FeatureFlags

  feature_flag :budgets

  before_action :load_budget
  before_action :load_set, only: [:edit, :update, :destroy]

  def new
    @set = @budget.sets.new
  end

  def create
    @set = @budget.sets.new(budget_set_params)

    if @set.save
      redirect_to admin_budget_path(@budget), notice: t("admin.budget_sets.create.notice")
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @set.update(budget_set_params)
      redirect_to admin_budget_path(@budget), notice: t("admin.budget_sets.update.notice")
    else
      render :edit
    end
  end

  def destroy
    @set.destroy!
    redirect_to admin_budget_path(@budget), notice: t("admin.budget_sets.destroy.success_notice")
  end

  private

    def load_budget
      @budget = Budget.find_by_slug_or_id! params[:budget_id]
    end

    def load_set
      @set = @budget.sets.find_by_slug_or_id! params[:id]
    end

    def budget_set_params
      params.require(:budget_set).permit(translation_params(Budget::Set))
    end
end
