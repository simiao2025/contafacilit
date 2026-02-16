import { Module } from '@nestjs/common';
import { CommonModule } from './common/common.module';
import { AuthModule } from './auth/auth.module';
import { IntegrationsModule } from './integrations/integrations.module';
import { TaxEngineModule } from './tax-engine/tax-engine.module';
import { AIModule } from './ai/ai.module';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ThrottlerModule.forRoot([{
      ttl: 60000,
      limit: 10,
    }]),
    CommonModule,
    AuthModule,
    IntegrationsModule,
    TaxEngineModule,
    AIModule,
  ],
})
export class AppModule { }
