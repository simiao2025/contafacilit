import { Module, Global } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { SecurityService } from './security.service';

@Global()
@Module({
    providers: [PrismaService, SecurityService],
    exports: [PrismaService, SecurityService],
})
export class CommonModule { }
