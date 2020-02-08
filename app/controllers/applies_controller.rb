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

  def edit_month
    @user = User.find(params[:id])
    @applies = Apply.where(authorizer: @user.id)
  end

  def update_month
    
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      applies_params.each do |id, item|
        apply = Apply.find(id)
        if item[:started_at].present? && item[:finished_at].blank?
          flash[:danger] = "出社時間と退社時間を入力してください"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return

        else
          apply.update_attributes!(item)
        end
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid  # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
    private

    def applies_params
      params.require(:apply).permit(:month, :mark, :authorizer)
      # params.permit(applies: [:month, :mark, :authorizer, :user_id])[:applies]
      # params.require(:user).permit(applies: [:month, :mark, :authorizer, :id, :user_id])[:applies]
    end
end
