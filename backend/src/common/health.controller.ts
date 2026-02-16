import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';

@Controller('health')
export class HealthController {
    constructor(private prisma: PrismaService) { }

    @Get()
    async check() {
        // Basic health check
        const dbStatus = await this.prisma.$queryRaw`SELECT 1`
            .then(() => 'up')
            .catch(() => 'down');

        return {
            status: dbStatus === 'up' ? 'ok' : 'error',
            timestamp: new Date().toISOString(),
            services: {
                database: dbStatus,
                api: 'up',
            },
        };
    }
}
