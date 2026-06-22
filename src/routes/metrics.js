import express from 'express'
import { collectDefaultMetrics, register } from 'prom-client';

const router = express.Router();

// Standaard metrics: CPU, memory, event loop
collectDefaultMetrics();

// // Custom counter
// const httpRequests = new Counter({
//     name: 'http_requests_total',
//     help: 'Total HTTP requests',
//     labelNames: ['method', 'path', 'status']
// });
//
// // Custom histogram
// const httpDuration = new Histogram({
//     name: 'http_request_duration_seconds',
//     help: 'HTTP request duration in seconds',
//     labelNames: ['method', 'path'],
//     buckets: [0.01, 0.05, 0.1, 0.5, 1, 5]
// });

// Endpoint
router.get('/', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});

export default router;