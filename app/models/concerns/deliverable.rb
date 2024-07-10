module Deliverable
  extend ActiveSupport::Concern

  FAILED_DELIVERY_STATUS = %w[soft_bounce hard_bounce blocked invalid_email error].freeze
  DELIVERED_STATUS = %w[delivered].freeze

  included do
    enum delivery_status: (FAILED_DELIVERY_STATUS + DELIVERED_STATUS).index_by(&:itself)
    validates :last_brevo_webhook_received_at, presence: true, if: -> { delivery_status.present? }
  end

  def human_delivery_status_and_date
    if delivered?
      if delivery_date == creation_date
        "Délivrée à #{delivery_hour}"
      else
        "Délivrée à #{delivery_hour} (le #{delivery_date})"
      end
    elsif delivery_failed?
      "Non délivrée"
    end
  end

  def delivery_failed?
    delivery_status.in?(FAILED_DELIVERY_STATUS)
  end

  def delivered?
    delivery_status.in?(DELIVERED_STATUS)
  end

  def creation_date
    created_at.strftime("%d/%m/%Y")
  end

  def delivery_date
    delivered_at&.strftime("%d/%m/%Y")
  end

  def delivery_hour
    delivered_at&.strftime("%H:%M")
  end

  def record_identifier
    "#{self.class.name.underscore}_#{id}"
  end

  def delivered_at
    last_brevo_webhook_received_at if delivered?
  end
end