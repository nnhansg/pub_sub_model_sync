# frozen_string_literal: true

module PubSubModelSync
  class Publisher
    attr_accessor :connector
    def initialize
      @connector = PubSubModelSync::Connector.new
    end

    def publish_data(klass, data, action)
      attributes = self.class.build_attrs(klass, action)
      log("Publishing data: #{[data, attributes]}")
      connector.topic.publish(data.to_json, attributes)
    end

    # @param settings (Hash): { attrs: [], as_class: nil, id: nil }
    def publish_model(model, action, settings = nil)
      settings ||= model.class.ps_msync_publisher_settings
      attributes = build_model_attrs(model, action, settings)
      data = {}
      data = model.as_json(only: settings[:attrs]) if action != 'destroy'
      log("Publishing model data: #{[data, attributes]}")
      connector.topic.publish(data.to_json, attributes)
    end

    def self.build_attrs(klass, action, id = nil)
      {
        class: klass.to_s,
        action: action.to_sym,
        id: id,
        service_model_sync: true
      }
    end

    private

    def build_model_attrs(model, action, settings)
      as_class = (settings[:as_class] || model.class.name).to_s
      id_val = model.send(settings[:id] || :id)
      self.class.build_attrs(as_class, action, id_val)
    end

    def log(msg)
      PubSubModelSync::Config.log(msg)
    end
  end
end
