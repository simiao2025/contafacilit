import { Module } from '@nestjs/common';
import { AIService } from './ai.service';
import { OpenAIService } from './services/openai.service';
import { VectorService } from './services/vector.service';

@Module({
    providers: [AIService, OpenAIService, VectorService],
    exports: [AIService],
})
export class AIModule { }
