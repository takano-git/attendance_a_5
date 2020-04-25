require "csv"

class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :export_csv_attendance]
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info, :working_employees]
  before_action :not_admin_user, only: :show
  before_action :set_one_month, only: [:show, :export_csv_attendance]
  before_action :set_apply_month, only: :show

  def index
    @users = User.paginate(page: params[:page])
    # パラメータとして名前か性別を受け取っている場合は絞って検索する
    if params[:name].present?
      @searches = @users.get_by_name params[:name]
    end
  end

  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
    # 1ヶ月の勤怠認証の為
    @authorizers= User.where(superior: true ).where.not(id: @user.id)
    @applies = Apply.where(authorizer: @user.id).where(mark: 1)
    # 勤怠変更認証の為
    @change_attendances = Attendance.where(change_authorizer_id: @user.id).where(mark: 1)
    @overtime_attendances = Attendance.where(overtime_authorizer_id: @user.id).where(overtime_mark: 1)
  end

  def new
    @user = User.new
  end
  
  def create
    @user= User.new(user_params)
    if @user.save
      log_in @user # 保存成功後、ログインします。
      flash[:success] ='新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      # 更新に成功した場合の処理を記述します
      flash[:success] = 'ユーザー情報を更新しました。'
      redirect_to @user
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def import
    # fileはtmpに自動で一時保存される
    User.import(params[:file])
    redirect_to users_url
  end
  
  def edit_basic_info
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end


  # 管理権限者、または現在ログインしているユーザーを許可します。
  def show_admin_or_correct_user
    # @user = User.find(params[:user_id]) if @user.blank?
    @user = User.find(params[:id]) if @user.blank?
    unless current_user?(@user) || current_user.admin?
      flash[:danger] = "権限がありません。"
      redirect_to(root_url)
    end
  end

  def working_employees
    attendances = Attendance.where.not(started_at: nil).where(finished_at: nil)
    working_employees_ids = []
    attendances.each do |attendance|
      working_employees_ids.push(attendance.user_id)
    end
    @working_employees_ids = working_employees_ids
  end


  def export_csv_attendance
    head :no_content

    # users = User.where(town_id: params[:id]) users => @attendances
    # town = Town.find(params[:id])            town =>  @user
    #ファイル名を指定 ここはお好みで
    filename = @user.name + Date.current.strftime("%Y%m%d")

    csv1 = CSV.generate do |csv|
      #カラム名を1行目として入れる
      csv << Attendance.column_names

      @attendances.each do |attendance|
        #各行の値を入れていく
        csv << attendance.attributes.values_at(*Attendance.column_names)
      end
    end
    create_csv(filename, csv1)
  end


  private

    def create_csv(filename, csv1)
      #ファイル書き込み
      File.open("./#{filename}.csv", "w", encoding: "SJIS") do |file|
        file.write(csv1)
      end
      #send_fileを使ってCSVファイル作成後に自動でダウンロードされるようにする
      stat = File::stat("./#{filename}.csv")
      send_file("./#{filename}.csv", filename: "#{filename}.csv", length: stat.size)
    end

    def user_params
      params.require(:user).permit(:name, :email, :department,:password, :password_confirmation)
    end
    
    def basic_info_params
      params.require(:user).permit(:department, :basic_time, :work_time, :name, :email, :affiliation, :employee_number, :uid, :designated_work_start_time, :designated_work_end_time, :basic_work_time, :password, :password_confirmation)
    end
end
