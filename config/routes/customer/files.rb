get 'private/:path', to: 'files#download', 
  constraints: { path: /.+/ }
