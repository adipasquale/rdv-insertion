module Invitations
  class SendSms < BaseService
    include Rails.application.routes.url_helpers

    def initialize(invitation:)
      @invitation = invitation
    end

    def call
      check_phone_number!
      send_sms
    end

    private

    def check_phone_number!
      fail!("le téléphone doit être renseigné") if phone_number.blank?
    end

    def send_sms
      Rails.logger.info(content)
      return unless Rails.env.production?

      SendTransactionalSms.call(phone_number: phone_number, content: content)
    end

    def content
      "#{applicant.full_name},\nVous êtes allocataire du RSA. Vous bénéficiez d'un accompagnement personnalisé " \
        "dans le cadre de vos démarches d'insertion. Le département #{department.number} " \
        "(#{department.name.capitalize}) vous invite à prendre rendez-vous sans tarder, afin de choisir " \
        "l'horaire qui vous convient le mieux, à l'adresse suivante : " \
        "#{redirect_invitations_url(params: { token: @invitation.token }, host: ENV['HOST'])}\n" \
        "Pour tout problème ou difficultés pour prendre RDV, contactez le secrétariat au #{department.phone_number}." \
        " Ce RDV est obligatoire, en cas d'absence une sanction pourra être prononcée."
    end

    def department
      @invitation.department
    end

    def phone_number
      applicant.phone_number_formatted
    end

    def applicant
      @invitation.applicant
    end
  end
end