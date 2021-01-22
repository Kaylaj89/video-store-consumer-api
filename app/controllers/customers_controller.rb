class CustomersController < ApplicationController
  SORT_FIELDS = %w(name registered_at postal_code)

  before_action :parse_query_args
  before_action :find_customer, only: [:show, :currently_checked_out, :checkout_history]

  def index
    if @sort
      data = Customer.all.order(@sort)
    else
      data = Customer.all
    end

    data = data.paginate(page: params[:p], per_page: params[:n])

    render json: data.as_json(
      only: [:id, :name, :registered_at, :address, :city, :state, :postal_code, :phone, :account_credit],
      methods: [:videos_checked_out_count]
    )
  end

  def show
    customer = Customer.find_by(id: params[:id])

    if customer.nil?
      return render json: {ok: false, message: "Customer not found", errors: ['Not Found']}, status: :not_found
    end

    render json: customer.as_json(only: [:id, :name, :registered_at, :address, :city, :state, :postal_code, :phone, :account_credit],methods: [:videos_checked_out_count]), status: :ok
  end

    def currently_checked_out
    message = "#{@customer.name} does not currently have any checked out videos"
    videos = Video.parameterized_list(params[:sort], params[:n], params[:p]).filter { |video| video.rentals.any? {|rental| rental.customer == @customer && !rental.returned} }
    if videos.empty?
      render json: {
        ok: true,
        message: message,
        errors: [message]
      }, status: :ok
    else
      video_list = videos.map { |video|
        found_rental = video.rentals.find {|rental| rental.customer == @customer && !rental.returned}
        video_hash = {
          title: video.title,
          image_url: video.image_url,
          overview: video.overview,
          external_id: video.external_id,
          release_date: video.release_date,
          inventory: video.inventory,
          checkout_date: found_rental.checkout_date,
          checkin_date: (found_rental.created_at == found_rental.updated_at) ? nil : found_rental.updated_at,
          due_date: found_rental.due_date,
          available_inventory: video.available_inventory
        }
        video_hash
      }
      render json: video_list.as_json, status: :ok
    end
    return
  end

  def checkout_history
    message = "#{@customer.name} has not previously checked out any videos"
    videos = Video.parameterized_list(params[:sort], params[:n], params[:p]).filter { |video| video.rentals.any? {|rental| rental.customer == @customer && rental.returned} }
    if videos.empty?
      render json: {
        ok: true,
        message: message,
        errors: [message]
      }, status: :ok
    else
      video_list = videos.map { |video|
        found_rental = video.rentals.find {|rental| rental.customer == @customer && rental.returned }
        video_hash = {
          title: video.title,
          image_url: video.image_url,
          overview: video.overview,
          external_id: video.external_id,
          release_date: video.release_date,
          inventory: video.inventory,
          checkout_date: found_rental.checkout_date,
          checkin_date: (found_rental.created_at == found_rental.updated_at) ? nil : found_rental.updated_at,
          due_date: found_rental.due_date,
          available_inventory: video.available_inventory
        }
        video_hash
      }
      render json: video_list.filter { |video| !video.checkin_date.nil? }.as_json, status: :ok
    end
    return
  end

private
  def parse_query_args
    errors = {}
    @sort = params[:sort]
    if @sort and not SORT_FIELDS.include? @sort
      errors[:sort] = ["Invalid sort field '#{@sort}'"]
    end

    unless errors.empty?
      render status: :bad_request, json: { errors: errors }
    end
  end

  def customer_params
    params.permit(:name, :registered_at, :address, :city, :state, :postal_code, :phone, :videos_checked_out_count)
  end

  def find_customer
    @customer = Customer.find_by(id: params[:id])

    if @customer.nil?
      return render json: {ok: false, message: "Customer not found", errors: ['Not Found']}, status: :not_found
    end
  end
end
