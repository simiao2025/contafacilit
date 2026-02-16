import { Injectable, OnModuleInit } from '@nestjs/common';
import { IIntegrationProvider } from './interfaces/integration-provider.interface';

@Injectable()
export class ProvidersRegistry implements OnModuleInit {
    private providers = new Map<string, IIntegrationProvider>();

    onModuleInit() {
        // Aqui registraremos os provedores reais conforme forem implementados
        // this.register(new HotmartProvider());
    }

    register(provider: IIntegrationProvider) {
        this.providers.set(provider.name.toLowerCase(), provider);
    }

    getProvider(name: string): IIntegrationProvider | undefined {
        return this.providers.get(name.toLowerCase());
    }

    getAll(): IIntegrationProvider[] {
        return Array.from(this.providers.values());
    }
}
