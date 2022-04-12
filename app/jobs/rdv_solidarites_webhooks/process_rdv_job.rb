class WebhookProcessingJobError < StandardError; end

module RdvSolidaritesWebhooks
  class ProcessRdvJob < ApplicationJob
    def perform(data, meta)
      @data = data.deep_symbolize_keys
      @meta = meta.deep_symbolize_keys
      check_organisation!
      return if applicants.empty?
      return notify_unhandled_category_to_mattermost if unhandled_category?

      upsert_or_delete_rdv
      notify_applicants if should_notify_applicants?
    end

    private

    def check_organisation!
      return if organisation

      raise WebhookProcessingJobError, "Organisation not found for organisation id #{rdv_solidarites_organisation_id}"
    end

    def should_notify_applicants?
      matching_configuration.notify_applicant? && event.in?(%w[created destroyed])
    end

    def matching_configuration
      organisation.configurations.find_by(context: rdv_solidarites_rdv.category)
    end

    def unhandled_category?
      Configuration.contexts.keys.exclude?(rdv_solidarites_rdv.category) || matching_configuration.nil?
    end

    def notify_unhandled_category_to_mattermost
      MattermostClient.send_to_notif_channel(
        "Catégorie #{rdv_solidarites_rdv.category} non gérée dans l'organisation #{organisation.id}.\n" \
        "RDV #{rdv_solidarites_rdv.id} non traité pour Applicants #{applicant_ids} "
      )
    end

    def event
      @meta[:event]
    end

    def rdv_solidarites_rdv
      RdvSolidarites::Rdv.new(@data)
    end

    def rdv_solidarites_user_ids
      rdv_solidarites_rdv.user_ids
    end

    def applicants
      @applicants ||= Applicant.where(rdv_solidarites_user_id: rdv_solidarites_user_ids)
    end

    def applicant_ids
      applicants.pluck(:id)
    end

    def organisation
      @organisation ||= Organisation.find_by(rdv_solidarites_organisation_id: rdv_solidarites_organisation_id)
    end

    def rdv_solidarites_organisation_id
      @data[:organisation][:id]
    end

    def upsert_or_delete_rdv
      if event == "destroyed"
        DeleteRdvJob.perform_async(rdv_solidarites_rdv.id)
      else
        UpsertRecordJob.perform_async(
          "Rdv",
          rdv_solidarites_rdv.to_rdv_insertion_attributes,
          { applicant_ids: applicant_ids, organisation_id: organisation.id, rdv_context_ids: rdv_contexts.map(&:id) }
        )
      end
    end

    def rdv_contexts
      applicants.map do |applicant|
        # TODO: remove organisation_configuration.context when caegory available
        RdvContext.find_or_create_by!(
          applicant: applicant, context: matching_configuration.context
        )
      end
    end

    def notify_applicants
      applicants.each do |applicant|
        NotifyApplicantJob.perform_async(
          applicant.id,
          organisation.id,
          @data,
          event
        )
      end
    end
  end
end
