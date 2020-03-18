class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  
  # 出社/退社登録ボタンの機能
  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0), applying_started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0), applying_finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end
  
  def edit_one_month
    @change_authorizers= User.where(superior: true ).where.not(id: @user.id)
  end
  
  # まとめて勤怠変更の申請内容を送信する機能
  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
      
        attendance = Attendance.find(id)

        if item[:started_at].present? && item[:finished_at].blank?
          flash[:danger] = "出社時間と退社時間を入力してください"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        else
          if item[:applying_started_at].present? && attendance.started_at.nil?       # 新規の申請を想定　:applying_started_atに入力があ理、BDのattendance.started_atがnilだったら 
              # if item[:applying_started_at] != attendance.started_at.strftime("%H:%M") 
                attendance.mark = "1"                                                  # 申請中　のステータスをつける
                attendance.save
              # end
          elsif item[:applying_started_at].present? && attendance.started_at.present?       # 変更を想定　:applying_started_atに入力があ理、BDのattendance.started_atが存在したら 
            if item[:applying_started_at] != attendance.started_at.strftime("%H:%M:%S.%L") # trueになってしまったitem[:applying_started_at]　と　attendance.started_at が違えば
              attendance.mark = "1"                                                  # 申請中　のステータスをつける
              attendance.save
            end
          elsif item[:applying_finish_at].present? && attendance.finished_at.nil?      # :applying_finish_atに入力があり、attendance.finished_atがnilだったら
              attendance.mark = "1"                                                  # 申請中　のステータスをつける
              attendance.save
          elsif item[:applying_finish_at].present? && attendance.finished_at.present?      # :applying_finish_atに入力があったら
            if item[:applying_finish_at] != attendance.finished_at.strftime("%H:%M:%S.%L")      # true item[:applying_finished_at]　と　attendance.finished_at が違えば
              attendance.mark = "1"                                                  # 申請中　のステータスをつける
              attendance.save
            end
          elsif item[:applying_note].present?
            if item[:applying_note] != attendance.note
              attendance.mark = "1"
              attendance.save
            end
          end
          
          
          
          attendance.update_attributes!(item)
        end
      end
    end
    flash[:success] = "勤怠の変更を送信しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid  # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end

  
  def change_one_month
    @user = User.find(params[:id])
    @change_attendances = Attendance.where(change_authorizer_id: @user.id).where(mark: 1) 
    applicant_change_id_array = []
    @change_attendances.each do |change_attendance|
      applicant_change_id_array.push(change_attendance.user_id)
    end

    @applicant_change_id_array = applicant_change_id_array.uniq
  end
  


  # モーダルの変更申請まとめて更新機能
  def update_change_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        if item[:mark] == "2"
          attendance.previous_started_at = attendance.started_at if attendance.started_at.nil?
          attendance.previous_finished_at = attendance.finished_at
          attendance.started_at = item[:applying_started_at]
          attendance.finished_at = item[:applying_finished_at]
          attendance.note = item[:applying_note]
          attendance.mark = item[:mark]
          attendance.save
        end
      end
    end
    flash[:success] = "勤怠変更の申請を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid  # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end




 
  private
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :applying_started_at, :applying_finished_at, :note, :overtime_instruction, :instructor, :change_authorizer_id, :mark, :applying_note])[:attendances]
    end
    
    
    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      # @user = User.find(params[:id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end
    end
end
