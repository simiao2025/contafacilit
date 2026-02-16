import { Module } from '@nestjs/common';
import { IntegrationsService } from './integrations.service';
import { WebhooksController } from './webhooks.controller';
import { ProvidersRegistry } from './providers.registry';

@Module({
    controllers: [WebhooksController],
    providers: [IntegrationsService, ProvidersRegistry],
    exports: [IntegrationsService, ProvidersRegistry],
})
export class IntegrationsModule { }
