class Transaction < ActiveRecord::Base
  establish_connection :"abaco_#{Rails.env}"
end
