require 'date'

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
  
  # 1ヶ月の勤怠変更の申請内容を保存し送信する機能(申請者側)
  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|

        attendance = Attendance.find(id)
        if item[:started_at].present? && item[:finished_at].blank?
          flash[:danger] = "出社時間と退社時間を入力してください"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        else
          if item[:applying_started_at].present? && attendance.started_at.nil?       # 新規の申請を想定 :applying_started_atに入力があ理、BDのattendance.started_atがnilだったら 
              # if item[:applying_started_at] != attendance.started_at.strftime("%H:%M") 
                attendance.mark = "1"                                                  # 申請中 のステータスをつける

              # end
          elsif item[:applying_started_at].present? && attendance.started_at.present?       # 変更を想定 :applying_started_atに入力があ理、BDのattendance.started_atが存在したら 
            if item[:applying_started_at] != attendance.started_at.strftime("%H:%M:%S.%L") # trueになってしまったitem[:applying_started_at] と attendance.started_at が違えば
              attendance.mark = "1"                                                  # 申請中 のステータスをつける
            # elsif item[:applying_finished_at] != attendance.finished_at.strftime("%H:%M:%S.%L")
            #   attendance.mark = "1" 
            end
          elsif item[:applying_finish_at].present? && attendance.finished_at.nil?      # :applying_finish_atに入力があり、attendance.finished_atがnilだったら
              attendance.mark = "1"                                                  # 申請中 のステータスをつける

          elsif item[:applying_finished_at].present? && attendance.finished_at.present?      # :applying_finish_atに入力があったら
            if item[:applying_finished_at] != attendance.finished_at.strftime("%H:%M:%S.%L")      # true item[:applying_finished_at] と attendance.finished_at が違えば
              attendance.mark = "1"                                                  # 申請中 のステータスをつける
            end
          elsif attendance.started_at.present? && attendance.finished_at.present?      # 出社退社ボタンを押している日
            if item[:applying_started_at] != attendance.started_at.strftime("%H:%M:%S.%L") ||  item[:applying_finished_at] != attendance.finished_at.strftime("%H:%M:%S.%L")
              attendance.mark = "1"    # 申請中 のステータスをつける
            end
          elsif item[:applying_note].present?
            if item[:applying_note] != attendance.note
              attendance.mark = "1"
            end
          end
          attendance.save                      # attendance.mark = "1"のカラムだけ保存
          attendance.update_attributes!(item)  # その他にも送られたカラムを保存する
          # もし翌日チェックが入っていたら、１日たす
          if attendances_params[id][:tomorrow] =="1"
            attendance = Attendance.find(id)
            attendance.applying_finished_at = attendance.applying_finished_at + 1.day
            attendance.save
          end
        end
      end
    end
    flash[:success] = "勤怠の変更を送信しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid  # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end

  # モーダル表示（勤怠変更を承認するモーダル 上長側）
  def change_one_month
    @user = User.find(params[:id])
    @change_attendances = Attendance.where(change_authorizer_id: @user.id).where(mark: 1) 
    applicant_change_id_array = []
    @change_attendances.each do |change_attendance|
      applicant_change_id_array.push(change_attendance.user_id)
    end
    @applicant_change_id_array = applicant_change_id_array.uniq
  end
  
  # モーダルで勤怠変更申請まとめて更新機能(上長側)
  def update_change_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        # if item[:mark] == "2" && item[:check] == "0"
      
        if item[:mark] == "2" && item[:change_checked] == "1"  # 承認 全部保存されるパターン　:mark == "2"承認　＆＆ change_checked] == "1" 変更
          attendance.previous_started_at = attendance.started_at if attendance.started_at.nil?
          attendance.previous_finished_at = attendance.finished_at
          attendance.started_at = item[:applying_started_at]
          attendance.finished_at = item[:applying_finished_at]
          attendance.note = item[:applying_note]
          attendance.mark = item[:mark]
          attendance.previous_finished_at = attendance.finished_at
          attendance.attendance_changed = true
          attendance.approval_date = Date.today
          attendance.save
          
          
          # ここにログ表示の為の機能を追加（apply_countにカウント１をつける）。カウントが付いているものはログ表示対象。申請者の申請月のアプライを取ってくる。１個しかないはず。。。
          target_month = Date.today.change(month: attendance.worked_on.month) #  => Sun, 12 Apr 2020 
          
          range = target_month.beginning_of_month..target_month.end_of_month
          applies = Apply.where(user_id: attendance.user_id).where(month: range)
          
          applies.each do |apply|
            if apply.apply_count == 0
              # 1ヶ月の勤怠を上長に申請するボタンを押した時にprevious_started_atなどに値を入れる
              attendances = Attendance.where(worked_on: apply.month)
              attendances.each do |attendance|
                attendance.previous_started_at = attendance.started_at
                attendance.previous_finished_at = attendance.finished_at
                attendance.save
              end
              apply.apply_count = apply.apply_count + 1
              apply.save
            end
          end
        elsif item[:mark] == "3" && item[:change_checked] == "1" # 否認 マークのみ保存し後は保存しない
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

  # 残業申請の編集画面の機能（申請者側）
  def edit_overtime
    @user = User.find(params[:id])
    @overtime_attendances = Attendance.where(id: params[:overtime_attendance]).where(user_id: @user.id)
    @overtime_authorizers = User.where(superior: true ).where.not(id: @user.id)
  end
  
  # 残業申請の内容を保存する機能（申請の途中）
  def update_overtime
    
    attendances_params.each do |id, item|
      # とりあえずパラメを全部保存
      attendance = Attendance.find(id)
      attendance.update_attributes!(item)

      # worked_onのカラム情報から日付情報をovertime_finished_atカラムに入れる
      attendance = Attendance.find(id)
      at_date = attendance.worked_on.in_time_zone
      # at_hour = attendance.overtime_finished_at.hour + 9
      at_hour = attendance.overtime_applying_finished_at.hour
      # if at_hour > 24
      #   at_hour -= 24
      # end
      
      at_day = at_date.day
      if params[:user][:tomorrow] == "1"
         at_day = at_date.day + 1  
      end
      attendance.overtime_applying_finished_at = attendance.overtime_applying_finished_at.change(month: at_date.month, day: at_day, hour: at_hour, min: attendance.overtime_applying_finished_at.min)
      attendance.save
    end
    redirect_to user_url(date: params[:date]) #一応遷移した
  end

  def edit_judgment_overtime
    @user = User.find(params[:id])
    @judgment_overtime_attendances = Attendance.where(overtime_authorizer_id: @user.id).where(overtime_mark: 1) 
    judgment_overtime_attendances_id_array = []
    @judgment_overtime_attendances.each do |judgment_overtime_attendance|
      judgment_overtime_attendances_id_array.push(judgment_overtime_attendance.user_id)
    end
    # ユーザーIDが入る
    @judgment_overtime_attendances_id_array = judgment_overtime_attendances_id_array.uniq
  end
  
  def update_judgment_overtime
    @user = User.find(params[:id])
    attendances_params.each do |id, item|
      attendance = Attendance.find(id)
      if params[:user][:attendances][id][:change_checked] == "1"
        attendance.update_attributes!(item)

        # 
        attendance = Attendance.find(id)
        attendance.overtime_note = attendance.overtime_applying_note
        attendance.overtime_applying_note = ""
        attendance.overtime_finished_at = attendance.overtime_applying_finished_at
        attendance.overtime_applying_finished_at = ""
        attendance.save
      end
    end
    redirect_to user_url(@user) #一応遷移した
  end

  def log_index
    @user = User.find(params[:id])
    @attendances = Attendance.where(user_id: @user.id).where(attendance_changed: true)
      # if @logs.count > 0 
      #   @logs.each do |log|
      #     target_id = log.change_authorizer_id
      #     target_user = User.find_by(id: target_id)
      #     user_name = target_user.name
          
      #     user_name.present? 
          
      #   end
      # end
  end


  private

    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :applying_started_at, :applying_finished_at, :note,
      :overtime_instruction, :instructor, :change_authorizer_id, :mark, :applying_note, :change_checked, :overtime_finished_at,
      :overtime_note, :user_id, :overtime_mark, :overtime_authorizer_id, :tomorrow, :overtime_applying_finished_at,
      :attendance_changed, :overtime_applying_note])[:attendances]
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
