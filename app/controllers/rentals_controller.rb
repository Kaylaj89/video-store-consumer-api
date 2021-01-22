class RentalsController < ApplicationController
  before_action :require_video, only: [:check_out, :check_in]
  before_action :require_customer, only: [:check_out, :check_in]

  # TODO: make sure that wave 2 works all the way
  def check_out
    rental = Rental.new(video: @video, customer: @customer)
    rental[:due_date] = Date.today + 7.days
    if rental.save
      render status: :ok, json: {}
    else
      render status: :bad_request, json: { errors: rental.errors.messages }
    end
  end

  def check_in
    rental = Rental.first_outstanding(@video, @customer)
    unless rental
      return render status: :not_found, json: {
        errors: {
          rental: ["Customer #{@customer.id} does not have #{@video.title} checked out"]
        }
      }
    end
    rental.checkin_date = Date.today
    rental.returned = true
    if rental.save
      render status: :ok, json: {}
    else
      render status: :bad_request, json: { errors: rental.errors.messages }
    end
  end

  def overdue
    rentals = Rental.overdue.map do |rental|
      {
          title: rental.video.title,
          customer_id: rental.customer_id,
          name: rental.customer.name,
          postal_code: rental.customer.postal_code,
          checkout_date: rental.checkout_date,
          due_date: rental.due_date
      }
    end
    render status: :ok, json: rentals
  end

private
  # TODO: make error payloads arrays
  def require_video
    @video = Video.find_by title: params[:title]
    unless @video
      render status: :not_found, json: { errors: { title: ["No video with title #{params[:title]}"] } }
    end
  end

  def require_customer
    @customer = Customer.find_by id: params[:customer_id]
    unless @customer
      render status: :not_found, json: { errors: { customer_id: ["No such customer #{params[:customer_id]}"] } }
    end
  end
end
