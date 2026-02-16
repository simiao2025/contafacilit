import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma.service';
import { OpenAIService } from './openai.service';

@Injectable()
export class VectorService {
    constructor(
        private prisma: PrismaService,
        private openai: OpenAIService,
    ) { }

    /**
     * Realiza busca semântica em mensagens de IA isolada por tenant
     */
    async searchSimilarMessages(
        organizationId: string,
        query: string,
        limit: number = 5,
    ) {
        const queryEmbedding = await this.openai.getEmbedding(query);
        const vectorString = `[${queryEmbedding.join(',')}]`;

        // Consulta SQL pura para pgvector
        // Usamos o operador <=> para distância de cosseno
        const results: any[] = await this.prisma.$queryRawUnsafe(`
      SELECT 
        id, 
        content, 
        role,
        1 - (embedding <=> cast($1 as vector)) as similarity
      FROM "ai_messages"
      WHERE "organization_id" = $2 
        AND "deleted_at" IS NULL
      ORDER BY embedding <=> cast($1 as vector)
      LIMIT $3;
    `, vectorString, organizationId, limit);

        return results;
    }
}
