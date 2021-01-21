class VideosController < ApplicationController
  before_action :require_video, only: [:show, :currently_checked_out_to, :checkout_history]

  def create
    video = Video.new(
        title: params[:title],
        overview: params[:overview],
        release_date: params[:release_date],
        image_url: params[:image_url],
        external_id: params[:external_id],
        inventory: 1)

      if video.save
        render status: :ok, json: {}
      else
        render status: :bad_request, json: { errors: video.errors.messages }
      end

  end

  def index

    if params[:query]
      data = VideoWrapper.search(params[:query])
    else
      data = Video.all
    end

    render status: :ok, json: data
  end

  def show
    render(
      status: :ok,
      json: @video.as_json(
        only: [:title, :overview, :release_date, :inventory, :image_url],
        methods: [:available_inventory]
        )
      )
  end

    def currently_checked_out_to
    message = "#{@video.title} is not currently checked out to any customer"
    # customers = @video.currently_checked_out_to
    customers = Customer.parameterized_list(params[:sort], params[:n], params[:p]).filter { |customer| customer.rentals.any? {|rental| rental.video == @video && rental.created_at == rental.updated_at} }
    if customers.empty?
      render json: {
        ok: true,
        message: message,
        errors: [message]
      }, status: :ok
    else
      render json: customers.as_json(only: [:id, :name, :registered_at, :address, :city, :state, :postal_code, :phone, :account_credit],methods: [:videos_checked_out_count]), status: :ok
    end
    return
  end

  def checkout_history
    message = "#{@video.title} has not been previously checked out to any customer"
    # customers = @video.previously_checked_out_to
    customers = Customer.parameterized_list(params[:sort], params[:n], params[:p]).filter { |customer| customer.rentals.any? {|rental| rental.video == @video && rental.updated_at > rental.created_at} }
    if customers.empty?
      render json: {
        ok: true,
        message: message,
        errors: [message]
      }, status: :ok
    else
      render json: customers.as_json(only: [:id, :name, :registered_at, :address, :city, :state, :postal_code, :phone, :account_credit],methods: [:videos_checked_out_count]), status: :ok
    end
    return
  end

  private
  def video_params
    params.permit(:title, :overview, :release_date, :total_inventory, :available_inventory)
  end

  def require_video
    @video = Video.find_by(title: params[:title])
    unless @video
      render status: :not_found, json: { errors: { title: ["No video with title #{params["title"]}"] } }
    end
  end
end
