class InviteController < ApplicationController

  before_filter :authenticate_user!, :except => [:new,:create]

  def new
    @invite = Invite.new
  end

  def create
    @invite = Invite.new(params[:invite])

    if @invite.save
      redirect_to root_path, notice: 'Invite was successfully created.'
    else
      render action: "new"
    end
  end
  
end
