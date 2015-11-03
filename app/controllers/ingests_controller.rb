class IngestsController < ApplicationController
  #before_action :set_ingest, only: [:show,]
  before_action :authenticate_user!

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

    unless session[:ingest].class == NilClass
      session[:ingest].clear
    end
    @ingest = Ingest.new
    session[:failures] = {}
  end

  # GET /ingests/dryrun_results
  def dryrun_results

  end

  def ingest_repost
    @ingest = Ingest.new(session[:ingest])

    @dryrun_report = IngestRun.new.ingest(@ingest[:folder], nil, @ingest[:content], @ingest[:rights], @ingest[:filestore], @ingest[:parent], @ingest[:worktype],@ingest[:photographer], @ingest[:repository],false, self.current_user.get_ldap_email)

    respond_to do |format|
      format.html { render :dryrun_results }
    end
  end

  def collection
    #@collections_list = '<div id="html1"><ul><li id="york1234">test list!</li></ul></div>'.html_safe
    @collections_list = get_collections_tree
    render :partial => 'collections/index'
  end

  # POST /ingests
  # POST /ingests.json
  def create

    @ingest = Ingest.new(ingest_params)
    @dryrun_report = IngestRun.new.ingest(@ingest[:folder], params[:ingest][:file].tempfile, @ingest[:content], @ingest[:rights], @ingest[:filestore], @ingest[:parent], @ingest[:worktype],@ingest[:photographer], @ingest[:repository],@ingest[:dryrun], self.current_user.get_ldap_email)

    unless session[:ingest].class == NilClass
      session[:ingest].clear
    end

    #remove tmpfile to avoid massive session
    params[:ingest].delete :file
    session[:ingest] = ingest_params

    respond_to do |format|
      #if @ingest.save
      format.html { render :dryrun_results }
      #format.json { render :index, status: :created, location: @ingest }
      #else
      # format.html { render :new, notice: notice }
      #  format.json { render json: @ingest.errors, status: :unprocessable_entity }
      #end
    end
  end

  # edit?

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_ingest
    @ingest = Ingest.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ingest_params
    params.require(:ingest).permit(:folder, :file, :content, :rights, :worktype, :repository, :filestore, :parent, :photographer, :dryrun)
  end
end
