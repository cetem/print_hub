var Jobs = {
  listenRangeChanges: function() {
    $(document).on('keyup', 'input[name$="[range]"]', function() {
      var element = $(this);
      var validRanges = true, maxPage = undefined, rangePages = 0;
      var pages = parseInt(
        element.parents('.nested_item').find('input[name$="[pages]"]').val()
      );
      var ranges = element.val().trim().split(/\s*,\s*/).sort(function(r1, r2) {
        var r1Value = parseInt(r1.match(/^\d+/)) || 0;
        var r2Value = parseInt(r2.match(/^\d+/)) || 0;

        return r1Value - r2Value;
      });

      $.each(ranges, function(i, r) {
        var data = r.match(/^(\d+)(-(\d+))?$/);
        var n1 = data ? parseInt(data[1]) : undefined;
        var n2 = data ? parseInt(data[3]) : undefined;

        validRanges = validRanges && n1 && n1 > 0 && (!n2 || n1 < n2);
        validRanges = validRanges && (!maxPage || maxPage < n1);

        maxPage = n2 || n1;
        rangePages += n2 ? n2 + 1 - n1 : 1;
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
  
  listenTwoSidedChanges: function() {
    $(document).on('change', 'input[name$="[two_sided]"]', function() {
      Jobs.updatePricePerCopy();
    });
  },
  
  updatePricePerCopy: function() {
    $('input[name$="[price_per_copy]"]').each(function(i, ppc) {
      var twoSidedElement = $(ppc).parents('.nested_item:first').find(
        'input[name$="[two_sided]"].price_modifier'
      );
      var setting = twoSidedElement.is(':checked') ?
        $('#total_pages').data('pricePerTwoSided') :
        $('#total_pages').data('pricePerOneSided');

      $(ppc).val(
        PriceChooser.choose(setting, parseInt($('#total_pages').val()))
      );
    });
  }
};