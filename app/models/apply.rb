class Apply < ApplicationRecord
  belongs_to :user
  
  attr_accessor :check
  
  validates :month, presence: true

  validate :apply_is_invalid_without_a_authorizer       #所属長承認申請には所属長の選択が必要

  def apply_is_invalid_without_a_authorizer
    errors.add(:authorizer, "が必要です")if authorizer.blank? && mark == 2
  end

end
