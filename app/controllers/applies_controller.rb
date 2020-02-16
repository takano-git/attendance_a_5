class AppliesController < ApplicationController
  
  def update

    @user = User.find(params[:user_id])
    @apply = Apply.find(params[:apply][:id])
    # @apply = Apply.find_by(user_id: @user.id, month: @first_day)
    # @apply = Apply.where(user_id: @user.id).where(month: @first_day).first
    # apply = Apply.find_by(user_id: 2, mark: 1)
    
    # if @apply.update_attributes(authorizer: params[:authorizer], month: @first_day, mark: params[:mark])
    if @apply.update_attributes(applies_params)
      flash[:info] = "一か月分の承認申請しました"
    else
      flash[:danger] = "承認申請に失敗しました。やり直してください。"
    end
    redirect_to @user
  end

  def edit_month
    @user = User.find(params[:id])
    @applies = Apply.where(authorizer: @user.id).where(mark: 1)
    apply_id_array = []
    @applies.each do |apply|
      apply_id_array.push(apply.user_id)
    end
    
    @apply_id_array = apply_id_array.uniq
  end

  def update_month
  end
  
    private

    def applies_params
      params.require(:apply).permit(:month, :mark, :authorizer, :id, :apply_id)
    end
    
    def month_params
      params.require(:user).permit(applies: [:month, :mark, :authorizer, :id, :apply_id])[:applies]
    end
end
