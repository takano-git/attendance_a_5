Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'

  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
  # 拠点
  resources :offices, only: [:index, :create, :update, :destroy]
  
  resources :users do
    collection { post :import }
    member do
      get 'export_csv_attendance'          # /users/:id/export_csv_attendance          ユーザー一人分の勤怠をcsv出力
      get 'edit_basic_info'                # /users/:id/edit_basic_info　　　　　　　　ユーザーの基本情報編集
      patch 'update_basic_info'            # /users/:id/update_basic_info　　　　　　　
      get 'attendances/edit_one_month'     # /users/:id/attendances/edit_one_month　　　1ヶ月の勤怠をまとめて編集画面
      patch 'attendances/update_one_month' # /users/:id/attendances/update_one_month    1ヶ月の勤怠をまとめて保存
      get 'applies/edit_month'             # /users/:id/applies/edit_month　　　　　   モーダルで1ヶ月分勤怠の申請編集画面
      patch 'applies/update_month'         # /users/:id/applies/update_month　　　　
      get 'attendances/change_one_month'   # /users/:id/attendances/change_one_month　　モーダルで勤怠の変更申請まとめて編集画面
      patch 'attendances/update_change_one_month' # /users/:id/attendances/update_change_one_month　モーダルで勤怠の変更申請まとめて編集画面　　　
      get 'attendances/edit_overtime'   # /users/:id/attendances/edit_overtime　　モーダルで残業申請（申請者側）
      patch 'attendances/update_overtime' # /users/:id/attendances/update_overtime　　　　
      get 'attendances/edit_judgment_overtime'   # /users/:id/attendances/edit_judgment_overtime　　モーダルで残業申請のジャッジを編集（上長側）
      patch 'attendances/update_judgment_overtime' # /users/:id/attendances/update_judgment_overtime
      get 'attendances/log_index'   # /users/:id/attendances/log_index　　　　　　　　　モーダルで残業申請のジャッジを編集（上長側）
      get 'working_employees'       # /users/:id/working_employees　　　　　　　　　　　出勤中社員一覧
      get 'edit_system_info'  # /users/:id/edit_system_info
    end
    resources :attendances, only: :update  # /users/:user_id/attendances/:id 　　　　　出勤登録
    
    resources :applies, only: :update      # /users/:user_id/applies/:id　　　　　　　　最初の1ヶ月の勤怠申請
  end
end
