match 'password_resets/new' => 'password_resets#new',
      as: 'new_password_reset', via: :get
match 'password_resets' => 'password_resets#create',
      as: 'password_resets', via: :post
match 'password_resets/:token/edit' => 'password_resets#edit',
      as: 'edit_password_reset', via: :get
match 'password_resets/:token' => 'password_resets#update',
      as: 'update_password_reset', via: :patch
