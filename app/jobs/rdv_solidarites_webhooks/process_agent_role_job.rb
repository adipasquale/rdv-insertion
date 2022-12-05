module RdvSolidaritesWebhooks
  class ProcessAgentRoleJob < ApplicationJob
    def perform(data, meta)
      @data = data.deep_symbolize_keys
      @meta = meta.deep_symbolize_keys
      return if organisation.blank?

      # let's make sure the agent is created before we continue
      sleep 2
      raise "Could not find agent: #{@data[:agent]}" unless agent

      attach_agent_to_org if event == "created"
      remove_from_org if event == "destroyed"
    end

    private

    def event
      @meta[:event]
    end

    def rdv_solidarites_agent_id
      @data[:agent][:id]
    end

    def rdv_solidarites_organisation_id
      @data[:organisation][:id]
    end

    def organisation
      @organisation ||= Organisation.find_by(rdv_solidarites_organisation_id: rdv_solidarites_organisation_id)
    end

    def agent
      @agent ||= Agent.find_by(rdv_solidarites_agent_id: rdv_solidarites_agent_id)
    end

    def attach_agent_to_org
      agent.organisations << organisation unless agent.organisation_ids.include?(organisation.id)
    end

    def remove_from_org
      agent.delete_organisation(organisation)
    end
  end
end