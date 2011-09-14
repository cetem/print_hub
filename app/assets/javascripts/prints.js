var Print = {
  updateTotalPrice: function() {
    var freeCredit = parseFloat($('#customer_free_credit').val()) || 0.0;
    var payWithCash = 0.0, payWithBonus = 0.0, totalPrice = 0.0;

    $('.print_job:not([data-exclude-from-total])').each(function() {
      totalPrice += parseFloat($(this).data('price')) || 0;
    });

    $('.article_line:not([data-exclude-from-total])').each(function() {
      totalPrice += parseFloat($(this).data('price')) || 0;
    });

    if(freeCredit > totalPrice) {
      payWithCash = 0.0;
      payWithBonus = totalPrice;
    } else {
      payWithCash = totalPrice - freeCredit;
      payWithBonus = freeCredit;
    }

    $(Print.cashPrefix + '_amount').val(payWithCash.toFixed(3));
    $(Print.cashPrefix + '_paid').val(payWithCash.toFixed(3));
    $(Print.creditPrefix + '_amount').val(payWithBonus.toFixed(3));
    $(Print.creditPrefix + '_paid').val(payWithBonus.toFixed(3));
  },

  updatePrintJobPrice: function(printJob) {
    Jobs.updatePricePerCopy();

    var copies = parseInt(printJob.find('input[name$="[copies]"]').val());
    var pricePerCopy = parseFloat(
      printJob.find('input[name$="[price_per_copy]"]').val()
    );
    var rangePages = parseInt(
      printJob.find('input[name$="[range]"]').data('rangePages')
    );
    var pricePerOneSidedCopy = PriceChooser.choose(
      $('#total_pages').data('pricePerOneSided'), parseInt($('#total_pages').val())
    );
    var evenRange = rangePages - (rangePages % 2);
    var rest = (rangePages % 2) * pricePerOneSidedCopy;
    var jobPrice = (copies * (pricePerCopy * evenRange + rest)) || 0;
    var money = printJob.find('span.money');

    printJob.data('price', jobPrice);
    money.html(money.html().replace(/(\d+.)+\d+/, jobPrice.toFixed(3)));

    Print.updateTotalPrice();
  },

  updateArticleLinePrice: function(articleLine) {
    var units = parseInt(articleLine.find('input[name$="[units]"]').val());
    var unitPrice = parseFloat(
      articleLine.find('input[name$="[unit_price]"]').val()
    );
    var articlePrice = (units * unitPrice) || 0;
    var money = articleLine.find('span.money');

    articleLine.data('price', articlePrice);
    money.html(money.html().replace(/(\d+.)+\d+/, articlePrice.toFixed(3)));

    Print.updateTotalPrice();
  },

  clearCustomer: function() {
    $('#print_auto_customer_name').val('');
    $('#print_customer_id').val('');
    $('#customer_free_credit').val('');
    $('#link_to_customer_credit_detail').hide();

    Print.updateTotalPrice();
  },
  
  updateSubmitLabel: function() {
    var label = /^\s*$/.test($('#print_printer').val()) ?
      Print.saveMessage : Print.printMessage;

    $('#print_submit').attr('value', label);
  }
};

jQuery(function($) {
  if($('#ph_prints').length > 0) {
    $('.print_job').live('item:removed', function() {
      $(this).data('excludeFromTotal', true).find(
        '.page_modifier:first'
      ).trigger('ph:page_modification');

      Print.updateTotalPrice();
    });

    $('.article_line').live('item:removed', function() {
      $(this).data('excludeFromTotal', true);

      Print.updateTotalPrice();
    });

    $('input.autocomplete_field').live('autocomplete:update', function() {
      var item = $(this).data('item');

      if (item.pages) {
        var pages = item.pages;
        var printJob = $(this).parents('.print_job:first');
        var printJobDetailsLink = printJob.find('a.details_link');

        printJob.find('input[name$="[pages]"]').val(pages).attr('disabled', true);
        printJobDetailsLink.attr(
          'href', printJobDetailsLink.attr('href').replace(/\d+$/, item.id)
        ).show();
        printJob.find('.dynamic_details').text('');
        printJob.find('input[name$="[range]"]').val('').data(
          'rangePages', pages
        ).trigger('ph:page_modification');

        Print.updatePrintJobPrice(printJob);
      } else if (item.unit_price) {
        var unitPrice = parseFloat(item.unit_price).toFixed(3);
        var articleLine = $(this).parents('.article_line');

        articleLine.find('input[name$="[unit_price]"]').val(unitPrice);

        Print.updateArticleLinePrice(articleLine);
      } else if (item.free_credit) {
        var customerDetailsLink = $('#link_to_customer_credit_detail');
        $('#customer_free_credit').val(item.free_credit);

        customerDetailsLink.attr(
          'href', customerDetailsLink.attr('href').replace(/\d+/, item.id)
        ).show();

        Print.updateTotalPrice();
      }
    });

    $('#print_printer').change(function() {
      Print.updateSubmitLabel();
    });

    $('input[name="[print_auto_customer_name]"]').live('change', function() {
      if(/^\s*$/.test($(this).val())) {clearCustomer();}
    });

    $('input[name$="[auto_document_name]"]').live('change', function() {
      var element = $(this);
      var printJob = element.parents('.print_job');

      if(printJob.length > 0 && /^\s*$/.test(element.val())) {
        printJob.find('input[name$="[range]"]').data('rangePages', 0);
        printJob.find('input[name$="[pages]"]').val('').removeAttr('disabled');
        printJob.find('.dynamic_details').html('');
        printJob.find('a.details_link').hide();

        Print.updatePrintJobPrice(printJob);
      }
    });

    $('input[name$="[auto_article_name]"]').live('change', function() {
      var element = $(this);
      var articleLine = element.parents('.article_line');

      if(articleLine.length > 0 && /^\s*$/.test(element.val())) {
        articleLine.find('input[name$="[units]"]').val('0');
        articleLine.find('input[name$="[unit_price]"]').val('');

        Print.updateArticleLinePrice(articleLine);
      }
    });

    $('input[name$="[pages]"]').live('change keyup', function() {
      var element = $(this);
      var printJob = element.parents('.print_job');
      var range = printJob.find('input[name$="[range]"]');
      var autoDocument = printJob.find('input[name$="[auto_document_name]"]');

      if(!element.attr('disabled') && parseInt(element.val()) > 0) {
        range.attr('disabled', true);
        autoDocument.attr('disabled', true);
      } else {
        range.removeAttr('disabled');
        autoDocument.removeAttr('disabled');
      }
      
      range.data('rangePages', parseInt(element.val()));

      Print.updatePrintJobPrice(printJob);
    });

    Jobs.listenRangeChanges();
    Jobs.listenTwoSidedChanges();

    $('.page_modifier').live('change keyup ph:page_modification', function() {
      var totalPages = 0;

      $('.print_job').each(function(i, pj) {
        var copies = parseInt($(pj).find('input[name$="[copies]"]').val());
        var rangePages = parseInt(
          $(pj).find('input[name$="[range]"]').data('rangePages')
        );

        totalPages += (copies || 0) * (rangePages || 0);
      });

      $('#total_pages').val(totalPages);

      $('.print_job').each(function(i, pj) {
        Print.updatePrintJobPrice($(pj));
      });
    });

    $('.price_modifier').live('change keyup', function() {
      var element = $(this);

      if (element.parents('.print_job').length > 0) {
        Print.updatePrintJobPrice(element.parents('.print_job'));
      } else if (element.parents('.article_line').length > 0) {
        Print.updateArticleLinePrice(element.parents('.article_line'));
      }
    });

    $('a.details_link').live('ajax:success', function(event, data) {
      Helper.show(
        $(this).parents('.print_job').find('.dynamic_details').hide().html(data)
      );
    });

    $('#link_to_customer_credit_detail').live('ajax:success', function(event, data) {
      $.fancybox({'padding': 24, 'content': data});
    });
    
    Print.updateSubmitLabel();

    // Captura de atajos de teclado
    $(document).keydown(function(e) {
      var key = e.which;

      // CTRL + ALT + I = Agregar un trabajo
      if((key == 73 || key == 105) && e.ctrlKey && e.altKey) {
        $('#add_print_job_link').click();
        e.preventDefault();
      // CTRL + ALT + A = Agregar un artículo
      } else if((key == 65 || key == 97) && e.ctrlKey && e.altKey) {
        $('#add_article_line_link').click();
        e.preventDefault();
      // CTRL + ALT + P = Imprimir
      } else if((key == 80 || key == 112) && e.ctrlKey && e.altKey) {
        $('#print_submit').click();
        e.preventDefault();
      }
    });
  }
});