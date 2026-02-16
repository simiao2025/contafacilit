import { Injectable, Logger, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { SecurityService } from '../common/security.service';
import * as crypto from 'crypto';

@Injectable()
export class ComplianceService {
    private readonly logger = new Logger(ComplianceService.name);

    constructor(
        private prisma: PrismaService,
        private security: SecurityService,
    ) { }

    // ─── 1. Exclusão Total de Dados ─────────────────────────────
    async requestDataErasure(organizationId: string, requestedBy: string) {
        // Criar registro formal da solicitação
        const request = await (this.prisma as any).dataErasureRequest.create({
            data: {
                organizationId,
                requestedBy,
                status: 'PENDING',
                scope: { type: 'FULL_ORGANIZATION_ERASURE' },
            },
        });

        try {
            // Soft delete cascata em todas as tabelas
            const now = new Date();

            await this.prisma.$transaction([
                // Anonimizar dados fiscais (retenção legal)
                this.anonymizeFiscalData(organizationId),

                // Soft delete em entidades não-fiscais
                (this.prisma as any).aiMessage.updateMany({
                    where: { organizationId, deletedAt: null },
                    data: { deletedAt: now },
                }),
                (this.prisma as any).aiConversation.updateMany({
                    where: { organizationId, deletedAt: null },
                    data: { deletedAt: now },
                }),
                (this.prisma as any).user.updateMany({
                    where: { organizationId, deletedAt: null },
                    data: { deletedAt: now },
                }),
                (this.prisma as any).organization.update({
                    where: { id: organizationId },
                    data: { deletedAt: now, status: 'CANCELLED' },
                }),
            ]);

            // Gerar hash de integridade
            const hash = crypto
                .createHash('sha256')
                .update(`${organizationId}:${now.toISOString()}:ERASED`)
                .digest('hex');

            await (this.prisma as any).dataErasureRequest.update({
                where: { id: request.id },
                data: { status: 'COMPLETED', completedAt: now, integrityHash: hash },
            });

            // Auditoria
            await this.prisma.auditLog.create({
                data: {
                    organizationId,
                    userId: requestedBy,
                    event: 'LGPD_DATA_ERASURE_COMPLETED',
                    newData: { requestId: request.id, integrityHash: hash },
                } as any,
            });

            this.logger.log({ message: 'Data erasure completed', organizationId, requestId: request.id });
            return { requestId: request.id, status: 'COMPLETED', integrityHash: hash };
        } catch (error) {
            await (this.prisma as any).dataErasureRequest.update({
                where: { id: request.id },
                data: { status: 'FAILED', errorDetails: error.message },
            });
            throw error;
        }
    }

    // ─── 2. Anonimização Reversível ─────────────────────────────
    private anonymizeFiscalData(organizationId: string) {
        // Anonimiza campos PII mantendo a estrutura fiscal
        return (this.prisma as any).organization.update({
            where: { id: organizationId },
            data: {
                razaoSocial: this.security.encrypt(`ANONIMIZADO_${organizationId}`, organizationId),
                cnpj: '00000000000000', // CNPJ anonimizado
            },
        });
    }

    // ─── 3. Registro de Consentimento ───────────────────────────
    async registerConsent(
        organizationId: string,
        userId: string,
        consentType: string,
        scope: Record<string, any>,
        ipAddress?: string,
        userAgent?: string,
    ) {
        const consent = await (this.prisma as any).dataConsent.create({
            data: {
                organizationId,
                userId,
                consentType,
                status: 'GRANTED',
                scope,
                ipAddress,
                userAgent,
            },
        });

        await this.prisma.auditLog.create({
            data: {
                organizationId,
                userId,
                event: 'LGPD_CONSENT_GRANTED',
                newData: { consentId: consent.id, consentType, scope },
            } as any,
        });

        return consent;
    }

    async revokeConsent(organizationId: string, consentId: string, userId: string) {
        const consent = await (this.prisma as any).dataConsent.update({
            where: { id: consentId },
            data: { status: 'REVOKED', revokedAt: new Date() },
        });

        await this.prisma.auditLog.create({
            data: {
                organizationId,
                userId,
                event: 'LGPD_CONSENT_REVOKED',
                newData: { consentId, consentType: consent.consentType },
            } as any,
        });

        return consent;
    }

    // ─── 4. Políticas de Retenção ───────────────────────────────
    async getRetentionPolicies() {
        return (this.prisma as any).retentionPolicy.findMany({
            where: { isActive: true },
        });
    }

    async upsertRetentionPolicy(
        dataCategory: string,
        retentionDays: number,
        legalBasis: string,
    ) {
        return (this.prisma as any).retentionPolicy.upsert({
            where: { dataCategory },
            update: { retentionDays, legalBasis },
            create: { dataCategory, retentionDays, legalBasis },
        });
    }

    // ─── 5. Exportação de Auditoria ─────────────────────────────
    async exportAuditLogs(organizationId: string) {
        const logs = await this.prisma.auditLog.findMany({
            where: { organizationId },
            orderBy: { createdAt: 'asc' },
        });

        const exportData = {
            organizationId,
            exportedAt: new Date().toISOString(),
            totalRecords: logs.length,
            records: logs,
        };

        // Gerar hash de integridade do export
        const hash = crypto
            .createHash('sha256')
            .update(JSON.stringify(exportData))
            .digest('hex');

        await this.prisma.auditLog.create({
            data: {
                organizationId,
                event: 'LGPD_AUDIT_EXPORT',
                newData: { totalRecords: logs.length, integrityHash: hash },
            } as any,
        });

        return { ...exportData, integrityHash: hash };
    }
}
