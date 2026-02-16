import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';

@Injectable()
export class OpenAIService {
    private openai: OpenAI;

    constructor(private configService: ConfigService) {
        this.openai = new OpenAI({
            apiKey: this.configService.get<string>('OPENAI_API_KEY'),
        });
    }

    async getEmbedding(text: string): Promise<number[]> {
        const response = await this.openai.embeddings.create({
            model: 'text-embedding-3-small',
            input: text,
        });
        return response.data[0].embedding;
    }

    async chat(messages: OpenAI.Chat.ChatCompletionMessageParam[]) {
        return this.openai.chat.completions.create({
            model: 'gpt-4-turbo-preview',
            messages,
            temperature: 0.1, // Baixa temperatura para maior determinismo financeiro
        });
    }
}
