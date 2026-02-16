import {
    Injectable,
    NestInterceptor,
    ExecutionContext,
    CallHandler,
    Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class TraceInterceptor implements NestInterceptor {
    private readonly logger = new Logger(TraceInterceptor.name);

    intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
        const request = context.switchToHttp().getRequest();
        const traceId = uuidv4();
        request['trace_id'] = traceId;

        const { method, url, body } = request;
        const organizationId = request.user?.organizationId || 'unauthenticated';

        const now = Date.now();
        return next.handle().pipe(
            tap(() => {
                const duration = Date.now() - now;
                this.logger.log({
                    message: `Request completed`,
                    method,
                    url,
                    traceId,
                    organizationId,
                    duration: `${duration}ms`,
                } as any);
            }),
        );
    }
}
