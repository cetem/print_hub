get 'private/:path' => 'files#download',
    constraints: { path: /.+/ }
match 'download_barcode/:code' => 'files#download_barcode',
      as: 'download_barcode', via: :get
