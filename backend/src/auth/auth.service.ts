import { Injectable, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../common/prisma.service';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';

@Injectable()
export class AuthService {
    constructor(
        private prisma: PrismaService,
        private jwtService: JwtService,
        private configService: ConfigService,
    ) { }

    async validateUser(email: string, pass: string): Promise<any> {
        const user = await this.prisma.user.findUnique({ where: { email, deletedAt: null } } as any);
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

        // Registro de auditoria de login
        await this.prisma.auditLog.create({
            data: {
                organizationId: user.organizationId,
                userId: user.id,
                event: 'AUTH_LOGIN_SUCCESS',
                newData: { role: user.role },
            } as any
        });

        return {
            access_token: accessToken,
            refresh_token: refreshToken,
        };
    }

    async generateRefreshToken(userId: string): Promise<string> {
        const token = crypto.randomBytes(40).toString('hex');
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7); // 7 dias

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
        // Busca todos os tokens (incluindo revogados) para detectar reuso malicioso
        const allTokens = await this.prisma.refreshToken.findMany({
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
            throw new UnauthorizedException('Invalid refresh token');
        }

        // DETECÇÃO DE ROUBO DE TOKEN: Se o token já foi revogado, revoga TUDO do usuário
        if (foundToken.isRevoked) {
            await this.prisma.refreshToken.updateMany({
                where: { userId: foundToken.userId },
                data: { isRevoked: true },
            });

            await this.prisma.auditLog.create({
                data: {
                    organizationId: foundToken.user.organizationId,
                    userId: foundToken.userId,
                    event: 'SECURITY_TOKEN_REUSE_DETECTED',
                    oldData: { tokenId: foundToken.id },
                } as any
            });

            throw new ForbiddenException('Security breach detected. Sessions invalidated.');
        }

        // Verifica expiração
        if (new Date() > foundToken.expiresAt) {
            throw new UnauthorizedException('Expired refresh token');
        }

        // Rotação: Revoga o atual e cria um novo
        await this.prisma.refreshToken.update({
            where: { id: foundToken.id },
            data: { isRevoked: true },
        });

        return this.login(foundToken.user);
    }

    async logout(refreshToken: string, userId: string) {
        const allTokens = await this.prisma.refreshToken.findMany({
            where: { userId, isRevoked: false },
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

        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (user) {
            await this.prisma.auditLog.create({
                data: {
                    organizationId: user.organizationId,
                    userId: userId,
                    event: 'AUTH_LOGOUT',
                } as any
            });
        }
    }
}
