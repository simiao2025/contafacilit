import { Controller, Post, Body, UseGuards, Request, Get } from '@nestjs/common';
import { AuthService } from './auth.service';
import { Public } from './decorators/public.decorator';
import { ThrottlerGuard } from '@nestjs/throttler';
import { Role } from './enums/role.enum';
import { Roles } from './decorators/roles.decorator';

@Controller('auth')
export class AuthController {
    constructor(private authService: AuthService) { }

    @Public()
    @UseGuards(ThrottlerGuard)
    @Post('login')
    async login(@Body() body: any) {
        const user = await this.authService.validateUser(body.email, body.password);
        if (!user) {
            return { message: 'Invalid credentials' };
        }
        return this.authService.login(user);
    }

    @Public()
    @Post('refresh')
    async refresh(@Body('refresh_token') refreshToken: string) {
        return this.authService.refresh(refreshToken);
    }

    @Post('logout')
    async logout(@Body('refresh_token') refreshToken: string) {
        await this.authService.logout(refreshToken);
        return { message: 'Logged out' };
    }

    @Roles(Role.ADMIN)
    @Get('profile')
    getProfile(@Request() req) {
        return req.user;
    }
}
