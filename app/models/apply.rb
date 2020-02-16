class Apply < ApplicationRecord
  belongs_to :user
  
  attr_accessor :check
  
  validates :month, presence: true

end
