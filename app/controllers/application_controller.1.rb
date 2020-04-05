class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  
  $days_of_the_week = %w{日 月 火 水 木 金 土}
  $mark_status = %w{未 へ申請中 から承認済 から否認}
  $mark_change = %w{　 申請中 勤怠編集承認済 勤怠編集否認}

  # beforeフィルター
    
  # paramsハッシュからユーザーを取得します。
  def set_user
    @user = User.find(params[:id])
  end
    
  # ログイン済みのユーザーか確認します。
  def logged_in_user
    unless logged_in?
      flash[:danger] = "ログインしてください。"
      redirect_to login_url
    end
  end
    
  # アクセスしたユーザーが現在ログインしているユーザーか確認します。
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end
    
  # システム管理者権限かどうか確認します。
  def admin_user
    redirect_to root_url unless current_user.admin?
  end
  
  # システム管理者権限でないことを確認します。
  def not_admin_user
    redirect_to root_url unless !current_user.admin?
  end
  
  # ページ出力前に1ヶ月分のデータの存在を確認・セットします。
  def set_one_month
    # 参考演算子は結果を戻り値として返すので@first_dayに代入が可能
    @first_day = params[:date].nil? ? Date.current.beginning_of_month : params[:date].to_date
    @last_day = @first_day.end_of_month
    one_month = [*@first_day..@last_day] # 対象の月の日数を代入します。
    # ユーザーに紐づく一ヵ月のレコードを検索し取得します。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    
    unless one_month.count == @attendances.count # それぞれの件数(日数)が一致するか評価します。
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        # 繰り返し処理により、1ヶ月分の勤怠データを生成します。
        one_month.each { |day| @user.attendances.create!(worked_on: day) }
      end
      @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    end
    
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
      flash[:danger] = "ページ情報の取得に失敗しました、再アクセスしてください。"
      redirect_to root_url
  end
 
  #ページ出力前にその月の日々のattendance.overtime_markがnilなら0をセットします
  def check_overtime_mark
    @attendances.each do |attendance|
      if attendance.overtime_mark == nil
        attendance.overtime_mark = 0
      end
    end
  end
  
  
  # ページ出力前にその月のapply　モデルの存在を確認・セットします
  def set_apply_month
    if @user.applies.find_by(month: @first_day)
      @apply = @user.applies.find_by(month: @first_day)
    else
       @apply = @user.applies.create!(month: @first_day, user_id: @user.id)
    end
  end

end
