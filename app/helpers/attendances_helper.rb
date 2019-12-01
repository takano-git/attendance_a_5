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
end
