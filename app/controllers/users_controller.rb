class UsersController < ApplicationController
  def new
    @user = User.new
  end
  
  def create
    @user= User.new(user_params)
    if@user.save
      #保存に成功した処理
    else
      render :new
    end
  end
  
  def edit
  end
  
  private
  
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
