module Users
  class SyncWithRdvSolidarites < BaseService
    attr_reader :rdv_solidarites_user_id

    def initialize(user:)
      @user = user.reload # we need to be sure the associations are correctly loaded
      @rdv_solidarites_user_id = @user.rdv_solidarites_user_id
    end

    def call
      upsert_rdv_solidarites_user
      return if @user.rdv_solidarites_user_id.present?

      assign_rdv_solidarites_user_id!
    end

    private

    def assign_rdv_solidarites_user_id!
      @user.rdv_solidarites_user_id = @rdv_solidarites_user_id
      save_record!(@user)
    end

    def upsert_rdv_solidarites_user
      @rdv_solidarites_user_id.present? ? sync_with_rdv_solidarites : create_or_update_rdv_solidarites_user
    end

    def sync_with_rdv_solidarites
      sync_organisations
      sync_referents if @user.referents.present?
      update_rdv_solidarites_user
    end

    def create_or_update_rdv_solidarites_user
      if create_rdv_solidarites_user.success?
        @rdv_solidarites_user_id = create_rdv_solidarites_user.user.id
        return
      end

      # If the user already exists in RDV-S, we assign the user to the org by updating him.
      return handle_email_taken_error if email_taken_error?

      result.errors += create_rdv_solidarites_user.errors
      fail!
    end

    def handle_email_taken_error
      existing_rdvi_user = User.find_by(rdv_solidarites_user_id: user_id_from_email_taken_error)

      if existing_rdvi_user
        fail!(
          "Un usager avec cette adresse mail existe déjà sur RDVI avec d'autres attributs: " \
          "id #{existing_rdvi_user.id}"
        )
      else
        @rdv_solidarites_user_id = user_id_from_email_taken_error
        sync_with_rdv_solidarites
      end
    end

    def user_id_from_email_taken_error
      create_rdv_solidarites_user.error_details&.dig("email")&.first&.dig("id")
    end

    def email_taken_error?
      create_rdv_solidarites_user.error_details&.dig("email")&.any? { _1["error"] == "taken" }
    end

    def create_rdv_solidarites_user
      @create_rdv_solidarites_user ||= RdvSolidaritesApi::CreateUser.call(
        user_attributes:
          rdv_solidarites_user_attributes
            .merge(organisation_ids: rdv_solidarites_organisation_ids)
            .merge(referent_agent_ids: referent_rdv_solidarites_ids)
      )
    end

    def sync_organisations
      @sync_organisations ||= call_service!(
        RdvSolidaritesApi::CreateUserProfiles,
        rdv_solidarites_user_id: rdv_solidarites_user_id,
        rdv_solidarites_organisation_ids: rdv_solidarites_organisation_ids
      )
    end

    def sync_referents
      @sync_referents ||= call_service!(
        RdvSolidaritesApi::CreateReferentAssignations,
        rdv_solidarites_user_id: rdv_solidarites_user_id,
        rdv_solidarites_agent_ids: referent_rdv_solidarites_ids
      )
    end

    def update_rdv_solidarites_user
      @update_rdv_solidarites_user ||= call_service!(
        RdvSolidaritesApi::UpdateUser,
        user_attributes: rdv_solidarites_user_attributes,
        rdv_solidarites_user_id: rdv_solidarites_user_id
      )
    end

    def rdv_solidarites_user_attributes
      user_attributes = @user.attributes
                             .symbolize_keys
                             .slice(*User::SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES)
                             .transform_values(&:presence)
                             .compact
      user_attributes.delete(:email) if @user.conjoint?
      user_attributes
    end

    def rdv_solidarites_organisation_ids
      @user.organisations.map(&:rdv_solidarites_organisation_id)
    end

    def referent_rdv_solidarites_ids
      @user.referents.map(&:rdv_solidarites_agent_id)
    end
  end
end
