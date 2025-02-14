class SyncController < ApplicationController
    skip_before_action :verify_authenticity_token

    def sync_data
        data = params[:data]
    data.each do |item|
        user = User.find_by(handle: item[:"handle"])

        if user 
            user.update(sync_data_params(item))
        end
    end

private 

def sync_data_params(item) 
{
synced: true,
last_synced_at: Time.current,
}
end 
end 
