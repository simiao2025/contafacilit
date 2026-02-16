import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

@Injectable()
export class SecurityService {
    private readonly algorithm = 'aes-256-gcm';
    private readonly masterKey: Buffer;

    constructor(private configService: ConfigService) {
        const key = this.configService.get<string>('SECURITY_MASTER_KEY');
        if (!key || key.length !== 64) {
            throw new Error('SECURITY_MASTER_KEY must be a 64-character hex string');
        }
        this.masterKey = Buffer.from(key, 'hex');
    }

    /**
     * Encrypts a string using AES-256-GCM
     * @param text The text to encrypt
     * @param context Additional context (e.g., organizationId) for AAD
     */
    encrypt(text: string, context: string): string {
        const iv = crypto.randomBytes(12);
        const cipher = crypto.createCipheriv(this.algorithm, this.masterKey, iv);

        // Add context to Auth Tag (AAD)
        cipher.setAAD(Buffer.from(context));

        let encrypted = cipher.update(text, 'utf8', 'hex');
        encrypted += cipher.final('hex');

        const tag = cipher.getAuthTag().toString('hex');

        // Return as iv:tag:encrypted
        return `${iv.toString('hex')}:${tag}:${encrypted}`;
    }

    /**
     * Decrypts a string using AES-256-GCM
     * @param encryptedData The encrypted data in iv:tag:encrypted format
     * @param context The same context used during encryption
     */
    decrypt(encryptedData: string, context: string): string {
        const [ivHex, tagHex, encryptedText] = encryptedData.split(':');

        if (!ivHex || !tagHex || !encryptedText) {
            throw new Error('Invalid encrypted data format');
        }

        const iv = Buffer.from(ivHex, 'hex');
        const tag = Buffer.from(tagHex, 'hex');
        const decipher = crypto.createDecipheriv(this.algorithm, this.masterKey, iv);

        decipher.setAuthTag(tag);
        decipher.setAAD(Buffer.from(context));

        let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
        decrypted += decipher.final('utf8');

        return decrypted;
    }
}
