LocalLlm.configure do |c|
  # Where Ollama is running
  c.base_url = "http://localhost:11434"

  # Pick any models you actually have
  c.default_general_model = "qwen2:7b"
  c.default_fast_model    = "qwen2:7b"

  # Important: we want streaming from the gem
  c.default_stream = true
end
