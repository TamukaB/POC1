class OfflineSubmissionController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:sync]  
  
    def sync
      submissions = params[:submissions] || []
  
      submissions.each do |submission|
        OfflineSubmission.create(data: submission[:data])
      end
  
      render json: { message: "Synced successfully" }, status: :ok
    end
  
    def index
      @submissions = OfflineSubmission.all
      render json: @submissions
    end
  end
  