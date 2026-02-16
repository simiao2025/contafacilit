export enum IntegrationType {
    BANKING = 'BANKING',
    SALES_PLATFORM = 'SALES_PLATFORM',
    PAYMENTS = 'PAYMENTS',
}

export interface NormalizedTransaction {
    externalId: string;
    amount: number;
    description: string;
    occurredAt: Date;
    metadata?: any;
}

export interface SyncResult {
    syncedCount: number;
    lastSyncAt: Date;
}

export interface IIntegrationProvider {
    /**
     * Identificador do provedor (ex: 'hotmart', 'pluggy')
     */
    readonly name: string;

    /**
     * Valida a assinatura do webhook para segurança
     */
    validateWebhook(payload: any, signature: string): Promise<boolean>;

    /**
     * Transforma o payload do provedor em um formato padronizado
     */
    parseWebhook(payload: any): Promise<NormalizedTransaction[]>;

    /**
     * Sincronização via API (Polling/Fetch) se disponível
     */
    sync?(organizationId: string, credentials: any): Promise<SyncResult>;
}
