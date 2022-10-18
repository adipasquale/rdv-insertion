class InvalidateInvitationJobError < StandardError; end

class InvalidateInvitationJob < ApplicationJob
  def perform(invitation_id)
    invitation = Invitation.find(invitation_id)
    return if invitation.valid_until.present? && invitation.valid_until < Time.zone.now

    invalidate_invitation = Invitations::InvalidateLink.call(invitation: invitation)

    raise InvalidateInvitationJobError, invalidate_invitation.errors.join(" - ") unless invalidate_invitation.success?
  end
end