module Toastr
  module HasToast
    extend ActiveSupport::Concern

    module ClassMethods
      def has_toast(category, options = {})
        has_many :toasts, class_name: Toastr::Toast, as: :parent, dependent: :destroy

        begin
          alias_method "#{category}_for_toastr", category
        rescue
          raise ArgumentError.new "#{category} must be a defined instance method"
        end

        define_method category do
          raise 'Gotta persist activerecord first' unless self.persisted?
          toast = self.toasts.where(category: category).first_or_create

          case toast.status.to_sym
          when :cached
            if toast.is_stale?(options)
              toast.queue!
              return toast.cache_json.merge('toastr' => (toast.cache_json['toastr'] || {}).merge('stale' => true)) unless Rails.application.config.active_job.queue_adapter == :inline
            end
            toast.cache_json.merge('toastr' => (toast.cache_json['toastr'] || {}).merge('stale' => false))
          when :empty
            toast.queue!
            if Rails.application.config.active_job.queue_adapter == :inline
              toast.reload
              toast.cache_json.merge('toastr' => (toast.cache_json['toastr'] || {}).merge('stale' => false))
            elsif options[:empty_cache_json].present?
              options[:empty_cache_json]
            else
              {'toastr' => {'error' => 'Data not yet available' }}
            end
          when :queued
            if toast.cache_json.present?
              toast.cache_json.merge('toastr' => (toast.cache_json['toastr'] || {}).merge('stale' => true))
            else
              (options[:empty_cache_json] || {'toastr' => {'error' => 'Data not yet available'} })
            end
          end
        end

      end # has_toast

    end # ClassMethods

  end
end

ActiveRecord::Base.send :include, Toastr::HasToast
