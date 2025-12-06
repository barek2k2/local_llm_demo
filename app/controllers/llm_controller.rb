# app/controllers/llm_controller.rb
class LlmController < ApplicationController
  include ActionController::Live

  def index
    raw_models = LocalLlm.models

    # Normalize to an array of plain strings, e.g. ["qwen2:7b", "mistral", ...]
    @models = Array(raw_models).map do |m|
      if m.respond_to?(:[])
        m["name"] || m[:name] || m["model"] || m[:model] || m.to_s
      else
        m.to_s
      end
    end
  rescue => e
    Rails.logger.error("LocalLlm.models failed: #{e.class} - #{e.message}")
    @models = []
  end

  def stream
    response.headers["Content-Type"]      = "text/plain"   # or "text/event-stream", both fine for fetch
    response.headers["Cache-Control"]     = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    prompt = params[:prompt].to_s
    model  = params[:model].presence

    begin
      if model
        LocalLlm.ask(model, prompt, stream: true) do |chunk|
          response.stream.write chunk
        end
      else
        LocalLlm.fast(prompt, stream: true) do |chunk|
          response.stream.write chunk
        end
      end
    rescue => e
      Rails.logger.error("LlmController#stream error: #{e.class} - #{e.message}")
      # Optional: send error text once
      response.stream.write "[ERROR] #{e.message}"
    ensure
      response.stream.close
    end
  end


  def chatt
    response.headers["Content-Type"]      = "text/event-stream"
    response.headers["Cache-Control"]     = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    model_param = params[:model].presence
    model       = model_param || LocalLlm.config.default_general_model

    begin
      raw = params[:messages].to_s
      messages =
        if raw.present?
          JSON.parse(raw)
        else
          []
        end

      # `messages` is an array like:
      # [
      #   { "role" => "user", "content" => "Explain Ruby..." },
      #   { "role" => "assistant", "content" => "Ruby is..." },
      #   { "role" => "user", "content" => "When was it created?" }
      # ]

      LocalLlm.chat(model, messages, stream: true) do |chunk|
        response.stream.write chunk
      end

    rescue => e
      Rails.logger.error("LlmController#chatt error: #{e.class} - #{e.message}")
      response.stream.write "event: error\ndata: #{e.message}\n\n"
    ensure
      response.stream.close
    end
  end

end
