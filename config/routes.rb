Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'customers/:id/current', to: "customers#currently_checked_out", as: "customer_current_videos"
  get 'customers/:id/history', to: "customers#checkout_history", as: "customer_checkout_history"
  resources :customers, only: [:index, :show]

  get 'videos/:title/current', to: "videos#currently_checked_out_to", as: "video_current_customers"
  get 'videos/:title/history', to: "videos#checkout_history", as: "video_checkout_history"
  resources :videos, only: [:index, :show, :create], param: :title

  post "/rentals/:title/check-out", to: "rentals#check_out", as: "check_out"
  post "/rentals/:title/return", to: "rentals#check_in", as: "check_in"
  get "/rentals/overdue", to: "rentals#overdue", as: "overdue"

  root 'videos#index'

end
