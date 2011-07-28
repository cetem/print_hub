var Jobs = {
  listenRangeChanges: function(parent) {
    $('input[name$="[range]"]').live('keyup', function() {
      var element = $(this);
      var validRanges = true, maxPage = undefined, rangePages = 0;
      var pages = parseInt(
        element.parents(parent).find('input[name$="[pages]"]').val()
      );
      var ranges = element.val().trim().split(/\s*,\s*/).sort(function(r1, r2) {
        var r1Value = parseInt(r1.match(/^\d+/)) || 0;
        var r2Value = parseInt(r2.match(/^\d+/)) || 0;

        return r1Value - r2Value;
      });

      jQuery.each(ranges, function(i, r) {
        var data = r.match(/^(\d+)(-(\d+))?$/);
        var n1 = data ? parseInt(data[1]) : undefined;
        var n2 = data ? parseInt(data[3]) : undefined;

        validRanges = validRanges && n1 && n1 > 0 && (!n2 || n1 < n2);
        validRanges = validRanges && (!maxPage || maxPage < n1);

        maxPage = n2 || n1;
        rangePages += n2 ? n2 + 1 - n1 : 1
      });

      if((/^\s*$/.test(element.val()) || validRanges) &&
        (!pages || !maxPage || pages >= maxPage)) {
        element.removeClass('field_with_errors');

        if(/^\s*$/.test(element.val()) && pages) {
          element.data('rangePages', pages).trigger('change');
        } else if(!/^\s*$/.test(element.val()) && validRanges) {
          element.data('rangePages', rangePages).trigger('change');
        }
      } else {
        element.addClass('field_with_errors');
      }
    });
  },
  
  listenTwoSidedChanges: function(parent) {
    $('input[name$="[two_sided]"]').live('change', function() {
      var element = $(this);
      var priceElement = element.parents(parent).find(
        'input[name$="[price_per_copy]"]'
      );

      if(element.is(':checked')) {
        priceElement.val(element.data('pricePerTwoSided')).trigger('change');
      } else {
        priceElement.val(element.data('pricePerOneSided')).trigger('change');
      }
    });
  }
};