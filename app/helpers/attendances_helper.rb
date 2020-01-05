require 'rounding'
module AttendancesHelper
  
  def attendance_state(attendance)
    # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    # if文は条件式がtrueなら処理を実行し、falseならなにも処理を実行しない。つまりボタンは表示されない。
    if  Date.current == attendance.worked_on
      return '出勤' if attendance.started_at.nil?
      return '退勤' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    # Rubyではメソッドの最後の式のreturnを省略できるようだ。
    false
  end
  
  # 出社と退社時間を受け取り、在社時間を計算して返します。
  def working_times(start, finish)
    format("%.2f",(((finish.floor_to(15.minutes) - start.floor_to(15.minutes)) / 60) / 60.0))
  end
  
  # 勤怠時間を受け取り15分単位で切捨てて表示します
  def format_minute_per_fifteen(time)
    # 詳しい使い方はここを参照　https://github.com/brianhempel/rounding/blob/master/README.md
    (time.floor_to(15.minutes)).min
  end  
end
