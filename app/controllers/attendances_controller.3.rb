require 'date'

class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  before_action :not_admin_user, only:[:update, :edit_one_month, :update_one_month, :change_one_month, :update_change_one_month, :edit_overtime, :update_judgment_overtime, :log_index,]
  
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
    attendances_params.each do |id, item|
      attendance = Attendance.find(id)
      # 変更申請終了時間をあとで比較するために変数に入れる。
      if item[:applying_started_at].present? && item[:applying_finished_at].present? && item[:applying_change_authorizer_id].present?
        # 申請したattendanceの日にちをとるので、なんどやっても同じ日が入りズレない
        param_applying_finished_at = item[:applying_finished_at].to_time.change(month: attendance.worked_on.month).change(day: attendance.worked_on.day)
        # 翌日チェックが入っていたら変数に１日たす。
        # if params[:user][:attendances][id][:tomorrow] == "1"
        if item[:change_tomorrow] == "1"
          param_applying_finished_at = param_applying_finished_at + 1.day
        end
        param_applying_started_at = item[:applying_started_at].to_time.change(month: attendance.worked_on.month).change(day: attendance.worked_on.day)
      end

        # もし申請欄が３つとも入力があれば
        if item[:applying_started_at].present? && item[:applying_finished_at].present? && item[:applying_change_authorizer_id].present?
          # もし申請する退勤時間が出勤時間以降の士官だったら　申請処理へ進む
          if param_applying_started_at <= param_applying_finished_at
            ########### 申請処理に入る
            # 申請中 のステータスをつける
            attendance.mark = "1"
            attendance.save                      # attendance.mark = "1"のカラムだけ保存(申請中のフラグをBDに保存)
            attendance.update_attributes!(item)  # その他にも送られたカラムを保存する !がつくとバリデーションを通しバリでに引っかかるとエラーになる
  
            # もし翌日チェックが入っていたら、applying_finished_atに１日たす
            if attendances_params[id][:change_tomorrow] =="1"
              attendance = Attendance.find(id)
              attendance.applying_finished_at = attendance.applying_finished_at + 1.day
              attendance.save
            end
          end
        end   # if item[:applying_started_at].blank? && item[:applying_started_at].blank? && item[:change_authorizer_id].blank? のend
      end # attendances_params.each do |id, item| の終わり
    
    flash[:success] = "勤怠変更申請を更新しました。"
    redirect_to user_url(date: params[:date])
  end  # defの終わり

  # モーダル表示（勤怠変更を承認するモーダル 上長側）
  def change_one_month
    @user = User.find(params[:id])
    @change_attendances = Attendance.where(applying_change_authorizer_id: @user.id).where(mark: 1) 
    applicant_change_id_array = []
    @change_attendances.each do |change_attendance|
      applicant_change_id_array.push(change_attendance.user_id)
    end
    @applicant_change_id_array = applicant_change_id_array.uniq
    @view_date = params[:view_date]
  end
  
  # モーダルで勤怠変更申請まとめて更新機能(上長側)
  def update_change_one_month
    #ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
      
        if item[:change_checked] == "1"  # 全部保存される change_checked] == "1" 変更
        # if item[:mark] == "2" && item[:change_checked] == "1"  # 承認 全部保存されるパターン　:mark == "2"承認　＆＆ change_checked] == "1" 変更
          attendance.previous_started_at = attendance.started_at if attendance.started_at.nil?
          attendance.previous_finished_at = attendance.finished_at
          attendance.started_at = item[:applying_started_at]
          attendance.finished_at = item[:applying_finished_at]
          attendance.note = item[:applying_note]
          attendance.mark = item[:mark]
          attendance.change_checked = 0
          attendance.previous_finished_at = attendance.finished_at
          attendance.change_authorizer_id = attendance.applying_change_authorizer_id
          attendance.applying_change_authorizer_id = nil
          attendance.attendance_changed = true
          attendance.approval_date = Date.today
          attendance.save
          
          
            # ここにログ表示の為の機能を追加（apply_countにカウント１をつける）。カウントが付いているものはログ表示対象。申請者の申請月のアプライを取ってくる。１個しかないはず。。。
          if item[:mark] == "2"
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
          else
          # flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
          # redirect_to attendances_edit_one_month_user_url(date: params[:date])
          end
        end
    end
    flash[:success] = "勤怠変更の申請を更新しました。"  # 追加
    redirect_to user_url(date: params[:date])
  #escue ActiveRecord::RecordInvalid  # トランザクションによるエラーの分岐です。
  
  end

  # 残業申請の編集画面の機能（申請者側）
  def edit_overtime
    @user = User.find(params[:id])
    @overtime_attendances = Attendance.where(id: params[:overtime_attendance]).where(user_id: @user.id)
    @overtime_authorizers = User.where(superior: true ).where.not(id: @user.id)
  end
  
  # 残業申請の内容を保存し申請する機能（申請者側）
  def update_overtime
    attendances_params.each do |id, item|
      # もし承認者の入力がなかったら 戻る
      attendance = Attendance.find(id)
      # 基本勤務終了時間より早��申請をしていたら　戻る
      # 比較用変数を用意
    
      # 必須項目が全て入力済みだと　進む
      if item[:overtime_applying_finished_at].present? && item[:overtime_applying_note].present? && item[:overtime_authorizer_id].present?
        # 残業申請で送られたパラメをCTUからJST時間に変更し変数に入れる。（Time型　JST）日付けを申請したい日にちに変更
        param_overtime_applying_finished_at = item[:overtime_applying_finished_at].to_time.to_s.gsub(/0000/, '0900').to_time.change(month: attendance.worked_on.month).change(day: attendance.worked_on.day)
        # 翌日チェックが入っていたら残業申請変数に１日たす
        if params[:user][:tomorrow] == "1"
          param_overtime_applying_finished_at = param_overtime_applying_finished_at + 1.day
        end
        # 指定勤務終了時間を変数に入れる（Time型　JST）
        designated_work_end_time = User.find(attendance.user_id).designated_work_end_time.to_time.change(month: attendance.worked_on.month).change(day: attendance.worked_on.day)

        if param_overtime_applying_finished_at > designated_work_end_time
          attendance = Attendance.find(id)
          if attendance.update_attributes!(item)
            # worked_onのカラム情報から日付情報をovertime_finished_atカラムに入れる
            attendance = Attendance.find(id)
            # at_date = attendance.worked_on.in_time_zone
            # at_hour = attendance.overtime_applying_finished_at.hour
            # at_day = at_date.day
            # if params[:user][:tomorrow] == "1"
            #   at_day = at_date.day + 1  
            # end
            # attendance.overtime_applying_finished_at = attendance.overtime_applying_finished_at.change(month: at_date.month, day: at_day, hour: at_hour, min: attendance.overtime_applying_finished_at.min)
            attendance.overtime_applying_finished_at = param_overtime_applying_finished_at
            attendance.overtime_change_checked = 0
            attendance.save
        
            flash[:success] = "残業申請を送信しました。"
            redirect_to user_url(date: attendance.worked_on.beginning_of_month)
          else
            flash[:danger] = "残業申請に失敗しました。"
            redirect_to user_url(date: attendance.worked_on.beginning_of_month)
          end
        else
          flash[:danger] = "残業申請に失敗しました。残業申請の終了予定時間は基本勤務終了時間より遅い時間を入力して下さい。"
          redirect_to user_url(date: attendance.worked_on.beginning_of_month)
        end  
      else
         flash[:danger] = "残業申請に失敗しました。"
         redirect_to user_url(date: attendance.worked_on.beginning_of_month)
      end # if item[:overtime_applying_finished_at].present? && item[:overtime_applying_note].present? && item[:overtime_authorizer_id].present? のend
    end # attendances_params.each do |id, item|のend
  end # def update_overtimeのend


  # 残業申請承認画面表示（上長側）
  def edit_judgment_overtime
    @user = User.find(params[:id])
    @judgment_overtime_attendances = Attendance.where(overtime_authorizer_id: @user.id).where(overtime_mark: 1) 
    judgment_overtime_attendances_id_array = []
    @judgment_overtime_attendances.each do |judgment_overtime_attendance|
      judgment_overtime_attendances_id_array.push(judgment_overtime_attendance.user_id)
    end
    # ユーザーIDが入る
    @judgment_overtime_attendances_id_array = judgment_overtime_attendances_id_array.uniq
    @view_date = params[:view_date]
  end
  
  # 残業申請承認（上長側）
  def update_judgment_overtime
    params_view_date = []
    @user = User.find(params[:id])
    attendances_params.each do |id, item|
      attendance = Attendance.find(id)
      params_view_date.push params[:user][:attendances][id][:view_date]
      if params[:user][:attendances][id][:overtime_change_checked] == "1"  # 変更欄にチェックが入っていたら
        attendance.update_attributes!(item)
        attendance = Attendance.find(id)
        attendance.overtime_note = attendance.overtime_applying_note
        attendance.overtime_applying_note = ""
        attendance.overtime_finished_at = attendance.overtime_applying_finished_at
        attendance.overtime_applying_finished_at = ""
        attendance.save
      end
    end
    flash[:success] = "残業申請を更新しました。"
    # redirect_to user_url(@user)
    
    redirect_to user_url(date: params_view_date[0])
  end

  def log_index
    @user = User.find(params[:id])
    searchmonth = ""
    if params[:selected_month] == "1" || params[:selected_month] == "2" || params[:selected_month] == "3" || params[:selected_month] == "4" || params[:selected_month] == "5" || params[:selected_month] == "6" || params[:selected_month] == "7" || params[:selected_month] == "8" || params[:selected_month] == "9"
      searchmonth = "0" + params[:selected_month] #04()
    end


    if params[:selected_year] || params[:selected_month]
      searchword = params[:selected_year] + "-" + searchmonth
      @attendances = Attendance.where(user_id: @user.id).where(attendance_changed: true).where('worked_on LIKE ?', "#{searchword}%") #前方一致
    else
      @attendances = Attendance.where(user_id: @user.id).where(attendance_changed: true)
    end
  end
  
  private

    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :applying_started_at, :applying_finished_at, :note,
      :overtime_instruction, :instructor, :change_authorizer_id, :mark, :applying_note, :change_checked, :overtime_finished_at,
      :overtime_note, :user_id, :overtime_mark, :overtime_authorizer_id, :change_tomorrow, :overtime_applying_finished_at,
      :attendance_changed, :overtime_applying_note,:applying_change_authorizer_id, :view_date, :overtime_change_checked])[:attendances]
    end
    
    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?

      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end
    end
end
