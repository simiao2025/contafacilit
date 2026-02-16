import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
    stages: [
        { duration: '30s', target: 20 }, // Ramp-up para 20 usuários
        { duration: '1m', target: 20 },  // Sustenta 20 usuários
        { duration: '30s', target: 0 },  // Ramp-down
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% das reqs < 500ms
        http_req_failed: ['rate<0.01'],   // Taxa de erro < 1%
    },
};

export default function () {
    const url = __ENV.API_URL || 'http://localhost:3000';

    // 1. Health Check
    const healthRes = http.get(`${url}/health`);
    check(healthRes, {
        'health is 200': (r) => r.status === 200,
        'status is ok': (r) => r.json().status === 'ok',
    });

    sleep(1);
}
