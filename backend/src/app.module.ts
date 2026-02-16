import { Module } from '@nestjs/common';
import { CommonModule } from './common/common.module';
import { AuthModule } from './auth/auth.module';
import { IntegrationsModule } from './integrations/integrations.module';
import { TaxEngineModule } from './tax-engine/tax-engine.module';
import { AIModule } from './ai/ai.module';
import { LoggerModule } from './common/logger.module';
import { TraceInterceptor } from './common/interceptors/trace.interceptor';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { APP_INTERCEPTOR } from '@nestjs/core';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ThrottlerModule.forRoot([{
      ttl: 60000,
      limit: 10,
    }]),
    LoggerModule,
    CommonModule,
    AuthModule,
    IntegrationsModule,
    TaxEngineModule,
    AIModule,
  ],
  providers: [
    {
      provide: APP_INTERCEPTOR,
      useClass: TraceInterceptor,
    },
  ],
})
export class AppModule { }
