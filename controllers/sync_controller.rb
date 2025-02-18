class SyncController < ApplicationController
    before_action :authenticate_user!

def session_data
    render json: { session_state: current_user.get_session_state }
end 

def update_session_state
    if current_user.update(session_state: params[:session_state])
        render json: { status: 'success' }
    else
        render json: { status: 'error', errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end 
  end 
end 