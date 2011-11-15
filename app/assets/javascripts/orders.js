var Order = {
  updateTotalPrice: function() {
    var totalPrice = 0.0;
    var credit = parseFloat($('#user').data('credit')) || 0;
    
    $('.order_line:not([data-exclude-from-total])').each(function() {
      totalPrice += parseFloat($(this).data('price')) || 0;
    });
    
    if(totalPrice > 0 && (credit >= (totalPrice * Order.threshold))) {
      $('#not_printed').hide();
      $('#printed').show();
    } else if(totalPrice > 0) {
      $('#printed').hide();
      $('#not_printed').show();
    }
    
    var money = $('#total span.money');
    
    money.html(money.html().replace(/(\d+.)+\d+/, totalPrice.toFixed(3)));
  },
  
  updateOrderLinePrice: function(orderLine) {
    Jobs.updatePricePerCopy();
    
    var copies = parseInt(orderLine.find('input[name$="[copies]"]').val());
    var pages = parseInt(orderLine.find('input[name$="[pages]"]').val());
    var pricePerCopy = parseFloat(
      orderLine.find('input[name$="[price_per_copy]"]').val()
    );
    var pricePerOneSidedCopy = PriceChooser.choose(
      $('#total_pages').data('pricePerOneSided'), parseInt($('#total_pages').val())
    );
    var evenRange = pages - (pages % 2);
    var rest = (pages % 2) * pricePerOneSidedCopy;
    var olPrice = (copies * (pricePerCopy * evenRange + rest)) || 0;
    var money = orderLine.find('span.money');

    orderLine.data('price', olPrice.toFixed(3));
    money.html(money.html().replace(/(\d+.)+\d+/, olPrice.toFixed(3)));

    Order.updateTotalPrice();
  }
};

jQuery(function($) {
  if($('#ph_orders').length > 0) {
    $(document).on('ajax:success', 'a.details_link', function(event, data) {
      Helper.show(
        $(this).parents('.order_line').find('.dynamic_details').hide().html(data)
      );
    });

    $(document).on('item:removed', '.order_line', function() {
      $(this).data('excludeFromTotal', true).find(
        '.page_modifier:first'
      ).trigger('ph:page_modification');

      Order.updateTotalPrice();
    });

    Jobs.listenTwoSidedChanges();

    $(document).on('change keyup', '.price_modifier', function() {
      Order.updateOrderLinePrice($(this).parents('.order_line'));
    });

    $(document).on('change keyup ph:page_modification', '.page_modifier', function() {
      var totalPages = 0;

      $('.order_line').each(function() {
        var copies = parseInt($(this).find('input[name$="[copies]"]').val());
        var pages = parseInt($(this).find('input[name$="[pages]"]').val());

        totalPages += (copies || 0) * (pages || 0);
      });

      $('#total_pages').val(totalPages);

      $('.order_line').each(function() {Order.updateOrderLinePrice($(this));});
    });
  }
});