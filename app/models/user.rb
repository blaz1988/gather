class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :rsvps, dependent: :destroy
  has_many :organized_events, class_name: "Event", foreign_key: :organizer_id, inverse_of: :organizer, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true
end
