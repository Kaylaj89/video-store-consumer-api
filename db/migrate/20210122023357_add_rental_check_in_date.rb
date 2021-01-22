class AddRentalCheckInDate < ActiveRecord::Migration[6.1]
  def change
    add_column(:rentals, :checkin_date, :date)
  end
end
