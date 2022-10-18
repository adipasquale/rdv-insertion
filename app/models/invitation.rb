class Invitation < ApplicationRecord
  include Sendable

  belongs_to :applicant
  belongs_to :department
  belongs_to :rdv_context
  has_and_belongs_to_many :organisations

  attr_accessor :content

  validates :help_phone_number, :rdv_solidarites_token, :organisations, :link, :number_of_days_to_accept_invitation,
            :valid_until,
            presence: true
  validates :uuid, uniqueness: true, allow_nil: true
  validate :organisations_cannot_be_from_different_departments

  delegate :motif_category, :motif_category_human, to: :rdv_context

  enum format: { sms: 0, email: 1, postal: 2 }, _prefix: :format

  before_validation :verify_it_expires_in_more_than_5_days_if_postal, on: :create
  before_create :assign_uuid
  after_commit :set_rdv_context_status

  scope :sent, -> { where.not(sent_at: nil) }
  scope :sent_in_time_window, lambda { |number_of_days_before_action_required|
    where("sent_at > ?", number_of_days_before_action_required.days.ago)
  }
  scope :reminder, ->(reminder = true) { where(reminder: reminder) }
  scope :valid, -> { where("valid_until > ?", Time.zone.now) }

  def send_to_applicant
    case self.format
    when "sms"
      Invitations::SendSms.call(invitation: self)
    when "email"
      Invitations::SendEmail.call(invitation: self)
    when "postal"
      Invitations::GenerateLetter.call(invitation: self)
    end
  end

  def help_phone_number_formatted
    Phonelib.parse(help_phone_number).national
  end

  def as_json(_opts = {})
    super.merge(motif_category: motif_category)
  end

  def messages_configuration
    organisations.map(&:messages_configuration).compact.first
  end

  def number_of_days_before_expiration
    if expired?
      0
    else
      (valid_until.to_date - Time.zone.now.to_date).to_i
    end
  end

  def expired?
    valid_until < Time.zone.now
  end

  def sent_before?(date)
    sent_at.present? && sent_at <= date
  end

  def sent_after?(date)
    sent_at.present? && sent_at >= date
  end

  private

  def assign_uuid
    self.uuid = generate_uuid
  end

  def generate_uuid
    loop do
      uuid = SecureRandom.send(:choose, [*"A".."Z", *"0".."9"], 8)
      break uuid unless self.class.find_by(uuid: uuid)
    end
  end

  def organisations_cannot_be_from_different_departments
    return if organisations.map(&:department_id).uniq == [department_id]

    errors.add(:organisations, :invalid)
  end

  def verify_it_expires_in_more_than_5_days_if_postal
    return if !format_postal? || valid_until.blank? || valid_until > 5.days.from_now

    errors.add(:base, "La durée de validité de l'invitation pour un courrier doit être supérieure à 5 jours")
  end

  def set_rdv_context_status
    RefreshRdvContextStatusesJob.perform_async(rdv_context_id)
  end
end
