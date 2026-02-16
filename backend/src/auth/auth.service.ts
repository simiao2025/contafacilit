import { Injectable, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../common/prisma.service';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { crypto } from 'crypto';

@Injectable()
export class AuthService {
    constructor(
        private prisma: PrismaService,
        private jwtService: JwtService,
        private configService: ConfigService,
    ) { }

    async validateUser(email: string, pass: string): Promise<any> {
        const user = await this.prisma.user.findUnique({ where: { email } });
        if (user && await bcrypt.compare(pass, user.passwordHash)) {
            const { passwordHash, ...result } = user;
            return result;
        }
        return null;
    }

    async login(user: any) {
        const payload = {
            sub: user.id,
            org: user.organizationId,
            role: user.role
        };

        const accessToken = this.jwtService.sign(payload);
        const refreshToken = await this.generateRefreshToken(user.id);

        return {
            access_token: accessToken,
            refresh_token: refreshToken,
        };
    }

    async generateRefreshToken(userId: string): Promise<string> {
        const token = require('crypto').randomBytes(40).toString('hex');
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7); // 7 dias

        // Hash do token para salvar no banco
        const tokenHash = await bcrypt.hash(token, 10);

        await this.prisma.refreshToken.create({
            data: {
                userId,
                tokenHash,
                expiresAt,
            },
        });

        return token;
    }

    async refresh(refreshToken: string) {
        const allTokens = await this.prisma.refreshToken.findMany({
            where: { isRevoked: false, expiresAt: { gt: new Date() } },
            include: { user: true },
        });

        let foundToken: any = null;
        for (const t of allTokens) {
            if (await bcrypt.compare(refreshToken, t.tokenHash)) {
                foundToken = t;
                break;
            }
        }

        if (!foundToken) {
            throw new UnauthorizedException('Invalid or expired refresh token');
        }

        await this.prisma.refreshToken.update({
            where: { id: foundToken.id },
            data: { isRevoked: true },
        });

        return this.login(foundToken.user);
    }

    async logout(refreshToken: string) {
        const allTokens = await this.prisma.refreshToken.findMany({
            where: { isRevoked: false },
        });

        for (const t of allTokens) {
            if (await bcrypt.compare(refreshToken, t.tokenHash)) {
                await this.prisma.refreshToken.update({
                    where: { id: t.id },
                    data: { isRevoked: true },
                });
                break;
            }
        }
    }
}
