class AppliesController < ApplicationController
  
  def update
    @user = User.find(params[:user_id])
    # @apply = Apply.find_by(user_id: @user.id)
     @apply = Apply.find_by(user_id: @user.id)
    
    # if @apply.update_attributes(authorizer: params[:authorizer], month: @first_day, mark: params[:mark])
    if @apply.update_attributes(applies_params)
      flash[:info] = "一か月分の承認申請しました"
    else
      flash[:danger] = "承認申請に失敗しました。やり直してください。"
    end
    redirect_to @user
  end
  
  def update_one_month
  end
  
    private

    def applies_params
      params.require(:apply).permit(:month, :mark, :authorizer)
      # params.permit(applies: [:month, :mark, :authorizer, :user_id])[:applies]
      # params.require(:user).permit(applies: [:month, :mark, :authorizer, :id, :user_id])[:applies]
    end
end
