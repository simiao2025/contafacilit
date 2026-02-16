import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { OpenAIService } from './services/openai.service';
import { VectorService } from './services/vector.service';

@Injectable()
export class AIService {
    private readonly logger = new Logger(AIService.name);

    constructor(
        private prisma: PrismaService,
        private openai: OpenAIService,
        private vector: VectorService,
    ) { }

    async processQuery(organizationId: string, userId: string, conversationId: string, prompt: string) {
        // 1. Recuperar contexto semântico (RAG)
        const similarMessages = await this.vector.searchSimilarMessages(organizationId, prompt);
        const context = similarMessages.map(m => m.content).join('\n---\n');

        // 2. Recuperar histórico da conversa
        const history = await (this.prisma as any).aiMessage.findMany({
            where: { conversationId, deletedAt: null },
            orderBy: { createdAt: 'asc' },
            take: 10, // Últimas 10 mensagens
        });

        // 3. Montar Prompt
        const systemPrompt = `Você é o assistente inteligente da ContaFacilit, um sistema de contabilidade digital.
      Trabalhe com os dados fornecidos abaixo para responder ao usuário.
      REGRAS:
      - NUNCA mencione dados de outras empresas.
      - Seja profissional e técnico.
      - Se não souber a resposta com base no contexto, peça para o usuário consultar o dashboard.
      CONTEXTO DO CLIENTE:
      ${context}`;

        const messages: any[] = [
            { role: 'system', content: systemPrompt },
            ...history.map(msg => ({
                role: msg.role.toLowerCase(),
                content: msg.content
            })),
            { role: 'user', content: prompt }
        ];

        // 4. Chamar OpenAI
        const response = await this.openai.chat(messages);
        const reply = response.choices[0].message.content || 'Desculpe, ocorreu um erro no processamento.';

        // 5. Persistir e Embedar a resposta (Background)
        const embedding = await this.openai.getEmbedding(reply);

        const savedMessage = await (this.prisma as any).aiMessage.create({
            data: {
                conversationId,
                organizationId,
                userId,
                role: 'ASSISTANT',
                content: reply,
                // Prisma não suporta diretamente a inserção de vetores na criação via API tipada
                // mas podemos usar executeRaw se necessário ou deixar como Unsupported
            } as any
        });

        // Atualiza o embedding via SQL pura
        const vectorString = `[${embedding.join(',')}]`;
        await this.prisma.$executeRawUnsafe(
            `UPDATE "ai_messages" SET embedding = cast($1 as vector) WHERE id = $2`,
            vectorString, savedMessage.id
        );

        // 6. Auditoria
        await this.prisma.auditLog.create({
            data: {
                organizationId,
                userId,
                event: 'AI_QUERY_PROCESSED',
                newData: {
                    tokens: response.usage?.total_tokens,
                    model: response.model
                }
            } as any
        });

        return reply;
    }
}
