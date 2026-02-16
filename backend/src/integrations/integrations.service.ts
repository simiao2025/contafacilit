import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { SecurityService } from '../common/security.service';
import { ProvidersRegistry } from './providers.registry';

@Injectable()
export class IntegrationsService {
    constructor(
        private prisma: PrismaService,
        private security: SecurityService,
        private registry: ProvidersRegistry,
    ) { }

    async getActiveIntegrations(organizationId: string) {
        return (this.prisma as any).integration.findMany({
            where: { organizationId, isActive: true },
        });
    }

    async getDecryptedCredentials(integrationId: string, organizationId: string) {
        const integration = await (this.prisma as any).integration.findUnique({
            where: { id: integrationId },
        });

        if (!integration || integration.organizationId !== organizationId) {
            throw new NotFoundException('Integration not found');
        }

        // Descriptografa usando o SecurityService da Fase 4
        const decrypted = this.security.decrypt(
            integration.credentialsVaultId,
            organizationId,
        );

        return JSON.parse(decrypted);
    }

    // Futuro: Método para disparar sincronização manual
}
