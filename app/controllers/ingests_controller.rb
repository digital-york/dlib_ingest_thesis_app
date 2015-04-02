class IngestsController < ApplicationController
  before_action :set_ingest, only: [:show]

  # GET /ingests
  # GET /ingests.json
  def index
    #@ingests = Ingest.all
  end

  # GET /ingests/1
  # GET /ingests/1.json
  def show
  end

  # GET /ingests/new
  def new
    @ingest = Ingest.new
    session[:failures] = {}
  end

  # POST /ingests
  # POST /ingests.json
  def create
    @ingest = Ingest.new(ingest_params)
    if @ingest[:content] != '' and @ingest[:file] != '' and @ingest[:rights] != ''
      if @ingest[:content].start_with? 'image'
        count,failed_lines = IngestImages.new.open_file(@ingest[:folder], params[:ingest][:file].tempfile, @ingest[:content], @ingest[:rights], @ingest[:photographer], @ingest[:worktype], @ingest[:repository], @ingest[:filestore], @ingest[:parent])
        notice = count
        session[:failures] = failed_lines
      else
        count,failed_lines = IngestItems.new.open_file(@ingest[:folder], params[:ingest][:file].tempfile, @ingest[:content], @ingest[:rights], @ingest[:filestore], @ingest[:parent])
        notice = count
        session[:failures] = failed_lines
      end
    else
      notice = 'Make sure all fields are completed'
    end

    respond_to do |format|
      #if @ingest.save
        format.html { redirect_to @ingest, notice: notice }
        format.json { render :index, status: :created, location: @ingest }
      #else
      #  format.html { render :new }
      #  format.json { render json: @ingest.errors, status: :unprocessable_entity }
      #end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ingest
      @ingest = Ingest.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ingest_params
      params.require(:ingest).permit(:folder, :file, :content, :rights, :worktype, :repository, :filestore, :parent, :photographer)
    end
end
