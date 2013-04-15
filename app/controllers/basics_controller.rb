class BasicsController < ApplicationController
  # GET /basics
  # GET /basics.json
  def index
    @basics = Basic.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @basics }
    end
  end

  # GET /basics/1
  # GET /basics/1.json
  def show
    @basic = Basic.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @basic }
    end
  end

  # GET /basics/new
  # GET /basics/new.json
  def new
    @basic = Basic.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @basic }
    end
  end

  # GET /basics/1/edit
  def edit
    @basic = Basic.find(params[:id])
  end

  # POST /basics
  # POST /basics.json
  def create
    @basic = Basic.new(params[:basic])

    respond_to do |format|
      if @basic.save
        format.html { redirect_to @basic, notice: 'Basic was successfully created.' }
        format.json { render json: @basic, status: :created, location: @basic }
      else
        format.html { render action: "new" }
        format.json { render json: @basic.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /basics/1
  # PUT /basics/1.json
  def update
    @basic = Basic.find(params[:id])

    respond_to do |format|
      if @basic.update_attributes(params[:basic])
        format.html { redirect_to @basic, notice: 'Basic was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @basic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /basics/1
  # DELETE /basics/1.json
  def destroy
    @basic = Basic.find(params[:id])
    @basic.destroy

    respond_to do |format|
      format.html { redirect_to basics_url }
      format.json { head :no_content }
    end
  end
end
