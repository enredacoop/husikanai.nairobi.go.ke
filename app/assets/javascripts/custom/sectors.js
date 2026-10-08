(function() {
  "use strict";
  App.Sectors = {
    // Keeps only the sub-sectors of the selected sector in the sub-sector select
    filterSubSectors: function(sectorSelect) {
      var subSectorSelect = $(sectorSelect.data("sub-sector-select"));
      var allOptions = subSectorSelect.data("all-options");
      var sectorId = String(sectorSelect.val());
      var selected = subSectorSelect.val();

      if (!allOptions) {
        allOptions = subSectorSelect.find("option[data-sector-id]").clone();
        subSectorSelect.data("all-options", allOptions);
      }

      subSectorSelect.find("optgroup, option[data-sector-id]").remove();
      allOptions.filter(function() {
        return String($(this).data("sector-id")) === sectorId;
      }).clone().appendTo(subSectorSelect);

      subSectorSelect.val(subSectorSelect.find("option[value='" + selected + "']").length ? selected : "");
    },
    initialize: function() {
      $(".js-sector-select").each(function() {
        App.Sectors.filterSubSectors($(this));
      }).off("change.sectors").on("change.sectors", function() {
        App.Sectors.filterSubSectors($(this));
      });
    }
  };
}).call(this);
