class OfficesController < ApplicationController
  # before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :create, :update, :destroy]
  # before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :create, :update, :destroy]

  def index
   @offices = Office.all   # 一覧表示用
   @office = Office.new    # 新規作成用
  end
  
  def create
   @office = Office.new(office_params)
   
    if @office.save
       flash[:success] = "新しい拠点を登録しました。"
       redirect_to offices_url
    else
       flash[:danger] = "拠点の登録に失敗しました。"
       render index
    end
  end
  
  def update
    @office = Office.find(params[:id])
    if @office.update_attributes(office_params)
      # 更新に成功した場合の処理を記述します
      flash[:success] = '拠点情報を更新しました。'
      redirect_to offices_url
    else
      render :index
    end
  end
  
  def destroy
    @office = Office.find(params[:id])
    @office.destroy
    flash[:success] = "#{@office.name}のデータを削除しました。"
    redirect_to offices_url
  end
  
  
  private
  
  def office_params
    params.require(:office).permit(:name, :office_type)
  end
end
