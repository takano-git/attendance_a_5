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

  # 上長が勤怠の申請を承認・否認したものを保存する機能
  def update_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      month_params.each do |id, item|
        apply = Apply.find(id)
        if params[:user][:applies][id][:check] == "1"
          apply.update_attributes!(item)
          
          if apply.apply_count == 0
            apply.apply_count = apply.apply_count + 1
            apply.save
            
            apply_user_id = User.find(apply.user_id)
            attendance = Attendance.find(apply_user_id)
            attendance.previous_started_at = attendance.started_at
            attendance.previous_finished_at = attendance.finished_at
            attendance.save
          end
          
        end
      end
    end
    # flash[:success] = "1ヶ月分の勤怠申請を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to applies_update_month_user_url(date: params[:date])
  end

  
    private

    def applies_params
      params.require(:apply).permit(:month, :mark, :authorizer, :id, :apply_id)
    end
    
    def month_params
      params.require(:user).permit(applies: [:month, :mark, :check, :authorizer, :id, :apply_id])[:applies]
    end
end
