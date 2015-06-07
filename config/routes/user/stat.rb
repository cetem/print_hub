match 'printer_stats(.:format)' => 'stats#printers',
      as: 'printer_stats', via: :get
match 'user_stats(.:format)' => 'stats#users',
      as: 'user_stats', via: :get
match 'print_stats(.:format)' => 'stats#prints',
      as: 'print_stats', via: :get
