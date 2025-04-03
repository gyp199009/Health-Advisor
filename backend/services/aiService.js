const axios = require('axios');

class AIService {
  constructor() {
    this.models = {
      volcengine: {
        name: '火山方舟',
        apiKey: process.env.VOLCENGINE_API_KEY,
        endpoint:'https://ark.cn-beijing.volces.com/api/v3/chat/completions'
      },
      deepseek: {
        name: 'DeepSeek',
        apiKey: process.env.DEEPSEEK_API_KEY,
        endpoint: 'https://api.deepseek.com/v1/chat/completions'
      },
      openai: {
        name: 'OpenAI',
        apiKey: process.env.OPENAI_API_KEY,
        endpoint: 'https://api.openai.com/v1/chat/completions'
      },
      anthropic: {
        name: 'Anthropic',
        apiKey: process.env.ANTHROPIC_API_KEY,
        endpoint: 'https://api.anthropic.com/v1/messages'
      },
      ollama: {
        name: 'Ollama',
        endpoint: process.env.OLLAMA_API_ENDPOINT || 'http://localhost:11434'
      }
    };
  }

  async generateResponse(modelType, messages) {
    const model = this.models[modelType];
    if (!model) {
      throw new Error(`不支持的AI模型类型: ${modelType}`);
    }

    try {
      let response;
      const headers = {
        'Content-Type': 'application/json'
      };

      if (model.apiKey) {
        headers['Authorization'] = `Bearer ${model.apiKey}`;
      }

      switch (modelType) {
        case 'volcengine':
          response = await axios.post(model.endpoint, {
            messages: messages.map(msg => ({
              role: msg.role,
              content: msg.content
            })),
            model: 'deepseek-r1-250120',
            temperature: 0.7,
            max_tokens: 2000
          }, { headers });
          return response.data.choices[0].message.content;

        case 'deepseek':
        case 'openai':
          response = await axios.post(model.endpoint, {
            messages: messages.map(msg => ({
              role: msg.role,
              content: msg.content
            })),
            model: modelType === 'openai' ? 'gpt-3.5-turbo' : 'default'
          }, { headers });
          return response.data.choices[0].message.content;

        case 'anthropic':
          response = await axios.post(model.endpoint, {
            messages: messages.map(msg => ({
              role: msg.role === 'assistant' ? 'assistant' : 'user',
              content: msg.content
            })),
            model: 'claude-2'
          }, { headers });
          return response.data.content[0].text;

        case 'ollama':
          response = await axios.post(`${model.endpoint}/api/chat`, {
            messages: messages.map(msg => ({
              role: msg.role,
              content: msg.content
            })),
            model: 'llama2'
          });
          return response.data.message.content;

        default:
          throw new Error(`未实现的AI模型类型: ${modelType}`);
      }
    } catch (error) {
      console.error(`AI服务错误 (${modelType}):`, error);
      throw new Error(`AI服务调用失败: ${error.message}`);
    }
  }

  getAvailableModels() {
    return Object.entries(this.models).map(([key, model]) => ({
      id: key,
      name: model.name
    }));
  }
}

module.exports = new AIService();