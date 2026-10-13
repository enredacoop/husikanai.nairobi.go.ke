(function() {
  "use strict";
  // A select with data-dependent-select="#child" filters the options of the
  // child select, whose options have data-parent-id. When no parent is
  // selected the child shows no options, or all of them (grouped) if it has
  // data-show-all-when-blank.
  App.DependentSelect = {
    filter: function(parent) {
      var child = $(parent.data("dependent-select"));
      var original = child.data("original-options");
      var parentId = String(parent.val());
      var selected = child.val();

      if (!original) {
        original = child.children("optgroup, option[data-parent-id]").clone();
        child.data("original-options", original);
      }

      child.children("optgroup, option[data-parent-id]").remove();

      if (parentId === "" && child.is("[data-show-all-when-blank]")) {
        original.clone().appendTo(child);
      } else {
        original.find("option").addBack("option").filter(function() {
          return String($(this).data("parent-id")) === parentId;
        }).clone().appendTo(child);
      }

      child.val(child.find("option[value='" + selected + "']").length ? selected : "");
    },
    initialize: function() {
      $("[data-dependent-select]").each(function() {
        App.DependentSelect.filter($(this));
      }).off("change.dependentSelect").on("change.dependentSelect", function() {
        App.DependentSelect.filter($(this));
      });
    }
  };
}).call(this);
