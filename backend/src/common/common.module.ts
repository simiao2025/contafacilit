import { Module, Global } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { SecurityService } from './security.service';
import { SqsService } from './sqs.service';

@Global()
@Module({
    providers: [PrismaService, SecurityService, SqsService],
    exports: [PrismaService, SecurityService, SqsService],
})
export class CommonModule { }
