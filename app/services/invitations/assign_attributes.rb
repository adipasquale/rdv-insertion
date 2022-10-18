module Invitations
  class AssignAttributes < BaseService
    def initialize(invitation:, rdv_solidarites_session:)
      @invitation = invitation
      @rdv_solidarites_session = rdv_solidarites_session
    end

    def call
      @invitation.token = invitation_token
      @invitation.link = invitation_link
    end

    private

    def invitation_user
      @invitation_user ||= RdvSolidaritesApi::RetrieveInvitation.call(
        token: last_sent_token,
        rdv_solidarites_session: @rdv_solidarites_session
      ).user
    end

    def applicant
      # we reload in case the applicant had a new invitation attached to it after
      # the invitation has been instantiated
      @invitation.applicant.reload
    end

    def retrieve_invitation_token
      @retrieve_invitation_token ||= call_service!(
        RdvSolidaritesApi::InviteUser,
        rdv_solidarites_user_id: applicant.rdv_solidarites_user_id,
        rdv_solidarites_session: @rdv_solidarites_session
      )
    end

    def last_sent_token
      @last_sent_token ||= applicant.last_sent_invitation&.token
    end

    # A token is no longer considered as valid if the invitation attached does not expire
    def last_sent_token_valid?
      last_sent_token.present? && invitation_user.present?
    end

    def invitation_token
      last_sent_token_valid? ? last_sent_token : retrieve_invitation_token.invitation_token
    end

    def compute_invitation_link
      @compute_invitation_link ||= call_service!(
        Invitations::ComputeLink,
        invitation: @invitation
      )
    end

    def invitation_link
      compute_invitation_link.invitation_link
    end
  end
end