class AttendancesController < ApplicationController
  
  def update
    @user = User.find(params[:user_id])
    @attendance = Ateendance.find(params[:id])
    # 
  end
end
