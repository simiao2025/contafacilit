import { Controller, Post, Body, Headers, Param, HttpCode, HttpStatus } from '@nestjs/common';
import { SqsService } from '../common/sqs.service';

@Controller('integrations/webhooks')
export class WebhooksController {
    constructor(private readonly sqsService: SqsService) { }

    @Post(':provider')
    @HttpCode(HttpStatus.ACCEPTED)
    async handleWebhook(
        @Param('provider') provider: string,
        @Body() payload: any,
        @Headers('x-hub-signature') signature: string, // Exemplo Kiwify/Hotmart
        @Headers('stripe-signature') stripeSignature: string,
    ) {
        // Nota: A validação de assinatura pode ser feita aqui ou no Worker.
        // Para maior resiliência e resposta rápida, enfileiramos e validamos no Worker.
        // Mas se o provedor exigir resposta imediata de falha (401), validamos aqui.

        await this.sqsService.pushEvent(provider, {
            body: payload,
            headers: {
                'x-hub-signature': signature,
                'stripe-signature': stripeSignature,
            },
        });

        return { message: 'Webhook received and queued for processing' };
    }
}
