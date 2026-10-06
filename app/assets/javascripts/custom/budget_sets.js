(function() {
  "use strict";
  App.BudgetSets = {
    toggle: function(button) {
      var container = button.closest(".sets-groups-and-headings");
      var expanded = button.attr("aria-expanded") === "true";

      container.find(".budget-set-button").attr("aria-expanded", "false");
      container.find(".budget-set-panel").prop("hidden", true);

      if (!expanded) {
        button.attr("aria-expanded", "true");
        $("#" + button.attr("aria-controls")).prop("hidden", false);
      }
    },
    initialize: function() {
      $(".budget-set-button").off("click.budgetSets").on("click.budgetSets", function() {
        App.BudgetSets.toggle($(this));
      });
    }
  };
}).call(this);
