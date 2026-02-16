import {
    Controller,
    Delete,
    Get,
    Post,
    Patch,
    Param,
    Body,
    Req,
    UseGuards,
} from '@nestjs/common';
import { ComplianceService } from './compliance.service';

@Controller('compliance')
export class ComplianceController {
    constructor(private compliance: ComplianceService) { }

    // ─── Exclusão de Dados (LGPD Art. 18) ───────────────────────
    @Delete('organizations/:orgId/data')
    async requestErasure(
        @Param('orgId') orgId: string,
        @Req() req: any,
    ) {
        const userId = req.user?.id || 'system';
        return this.compliance.requestDataErasure(orgId, userId);
    }

    // ─── Consentimento Open Finance ─────────────────────────────
    @Post('organizations/:orgId/consents')
    async registerConsent(
        @Param('orgId') orgId: string,
        @Body() body: { consentType: string; scope: Record<string, any> },
        @Req() req: any,
    ) {
        const userId = req.user?.id || 'system';
        const ip = req.ip;
        const ua = req.headers['user-agent'];
        return this.compliance.registerConsent(
            orgId,
            userId,
            body.consentType,
            body.scope,
            ip,
            ua,
        );
    }

    @Patch('consents/:consentId/revoke')
    async revokeConsent(
        @Param('consentId') consentId: string,
        @Body() body: { organizationId: string },
        @Req() req: any,
    ) {
        const userId = req.user?.id || 'system';
        return this.compliance.revokeConsent(body.organizationId, consentId, userId);
    }

    // ─── Políticas de Retenção ──────────────────────────────────
    @Get('retention-policies')
    async getRetentionPolicies() {
        return this.compliance.getRetentionPolicies();
    }

    @Post('retention-policies')
    async upsertRetentionPolicy(
        @Body() body: { dataCategory: string; retentionDays: number; legalBasis: string },
    ) {
        return this.compliance.upsertRetentionPolicy(
            body.dataCategory,
            body.retentionDays,
            body.legalBasis,
        );
    }

    // ─── Exportação de Auditoria ────────────────────────────────
    @Get('organizations/:orgId/audit-export')
    async exportAuditLogs(@Param('orgId') orgId: string) {
        return this.compliance.exportAuditLogs(orgId);
    }
}
