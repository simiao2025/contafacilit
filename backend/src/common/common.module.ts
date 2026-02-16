import { Module, Global } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { SecurityService } from './security.service';
import { SqsService } from './sqs.service';
import { HealthController } from './health.controller';

@Global()
@Module({
    controllers: [HealthController],
    providers: [PrismaService, SecurityService, SqsService],
    exports: [PrismaService, SecurityService, SqsService],
})
export class CommonModule { }
