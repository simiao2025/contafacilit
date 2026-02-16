import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';

@Injectable()
export class SqsService {
    private readonly sqsClient: SQSClient;
    private readonly queueUrl: string;
    private readonly logger = new Logger(SqsService.name);

    constructor(private configService: ConfigService) {
        this.sqsClient = new SQSClient({
            region: this.configService.get<string>('AWS_REGION', 'us-east-1'),
        });
        this.queueUrl = this.configService.get<string>('SQS_EVENTS_QUEUE_URL') || '';
    }

    async pushEvent(provider: string, payload: any, organizationId?: string) {
        try {
            const command = new SendMessageCommand({
                QueueUrl: this.queueUrl,
                MessageBody: JSON.stringify({
                    provider,
                    organizationId,
                    payload,
                    timestamp: new Date().toISOString(),
                }),
                MessageAttributes: {
                    Provider: { DataType: 'String', StringValue: provider },
                },
            });

            await this.sqsClient.send(command);
            this.logger.log(`Event from ${provider} pushed to SQS.`);
        } catch (error) {
            this.logger.error(`Failed to push event to SQS: ${error.message}`);
            throw error;
        }
    }
}
