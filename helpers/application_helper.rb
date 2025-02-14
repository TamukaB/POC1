module ApplicationHelper
    def bootstrap_class_for(flash_type)
      case flash_type.to_sym
      when :notice then "alert-success"  # ✅ Green for success
      when :alert then "alert-danger"    # ❌ Red for errors
      when :error then "alert-danger"    # ❌ Red for errors
      when :success then "alert-success" # ✅ Green for success
      when :warning then "alert-warning" # ⚠️ Yellow for warnings
      when :info then "alert-info"       # ℹ️ Blue for info
      else "alert-primary"
      end
    end
  end
  